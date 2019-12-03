%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "uthash.h"
#include "interpreter.h"
#include "util.h"

#define YYDEBUG TRUE

extern int yydebug;
extern FILE *yyin;
int yyerror (char *s);
int yylex ();

typedef struct tree Tree;
typedef struct symbol Symbol;
typedef struct error Error;

typedef struct tree {
    char label[100];
    Tree *left;
    Tree *right;
    int params;
    Program *code;
    char attrs[100];
} Tree;

typedef struct symbol {
    int id;
    char atom[60];
    union {
        int value;
        Program *subroutine;
        Program *vector;
    } data;
    UT_hash_handle hh;
} Symbol;

typedef struct error {
    char errorMsg[400];
    struct error* next;
} error;

int lines = 1;
int arity = 0;
int characters = 0;
char* sym;
char anotation[60];
error *errors= (error*)0;
int lex = FALSE;
int syntax = FALSE;
int hasSymbols = FALSE;
struct tree *aux = (Tree*)0;

Tree* AST = NULL;
Symbol* symbolTable = NULL;
int symbolID = 0;

void throwError(char* tkn);

void pushError(error **list, char *errorName);

void printErrors(error **list);

error *errorList = (error*)0;

Program* genCode(Tree* node, Type type, Instruction *lhs, Instruction *rhs);
Tree* createAnotatedNode(char* label, Tree* left, Tree* right, char* attrs);
Tree* createNode(char* label, Tree* left, Tree* right);
Tree* createLeaf(char* label);
void printNode(Tree* node);
void printTree(Tree* tree, int space);
void checkArity(char* symbol, int arity);

char* createFnAtom(char* s, int a) {
    char* str = (char*) malloc(sizeof(char)*60);
    snprintf(str, 60, "%s/%d", s, a);
    return str;
} 

Symbol* findAtom(char* atom) {
    Symbol* s = (Symbol*) malloc(sizeof(Symbol));
    HASH_FIND_STR(symbolTable, atom, s);
    if(s != NULL) return s;
    return NULL;
}

void addAtom(char* atom) {
    char errorMessage[400];
    if(findAtom(atom) == NULL) {
        Symbol* s = (Symbol*) malloc(sizeof(Symbol));
        strcpy(s->atom, atom);
        s->id = symbolID++;
        HASH_ADD_STR(symbolTable, atom, s);
        if(!hasSymbols) { hasSymbols = TRUE; }
    } else {
        snprintf(errorMessage, 400, "\nFunction already declared");
        yyerror(errorMessage);
    }
}

void checkArity(char* symbol, int arity) {
    char errorMessage[400];
    if(findAtom(createFnAtom(symbol, arity)) == NULL) {
        snprintf(errorMessage, 400, "\n%s with arity %d not declared previously", symbol, arity);
        yyerror(errorMessage);
    }
}


void printDelimiter() {
    printf("\n--------------------------------------------------------------------------\n\n");
}

void printSymbolTable() {
    if (hasSymbols) {
        Symbol *tmp = NULL;
        Symbol* s = (Symbol*) malloc(sizeof(Symbol));
        
        printDelimiter();
        printf("SYMBOL TABLE: \n\n");

        printf("|\tid\t|\tatom\t|\n\n");

        HASH_ITER(hh, symbolTable, s, tmp) {
            printf("|\t%d\t|\t%s\t|\n", s->id, s->atom);
            HASH_DEL(symbolTable, s);
            free(s);
        }
    } else return;
}

%}
%union {
	char *val;
    char opr;
    struct tree *node;
}

%token MAP
%token FILTER
%token DEFN
%token DEF
%token <node> ATOM
%token COUNT
%token CONS
%token HEAD
%token TAIL
%token NIL
%token <node> NUM
%token NOT
%token <opr> OPR
%token <val> LOGOPR
%token <val> COMPLOGOPR
%token READ
%token WRITE
%token IF

%type <val> list_iterator list_op log_opr opr
%type <node> term vector factor compound_factor command program statements statement write read def defn fnbody element expr

%%

program: 
    /* empty */
    {
        AST = NULL;
    }
    
    | statements
    { 
        AST = $1;
        if(syntax) { 
            if (lex) { printDelimiter(); }
            printf("\n\nAST: \n\n");
            printTree(AST, 0);
            printSymbolTable();
        }
        program = (Program*) malloc(sizeof(Program));
        program = $1->code;
        run(program, NULL);
    }

    | error
    {
        AST = NULL;
    }
    ;

statements: 
    statement
    {
        $$ = $1;
    }

    | statement statements
    {
        $$ = createNode("statements", $1, $2);
        $$->code = (Program*) malloc(sizeof(Program));
        $$->code = $1->code;
        $$->code->next_instruction = $2->code;
    }
    ;

statement:
        '('  command ')'   { $$ = $2; }
    |   '('  write   ')'   { $$ = $2; }
    |   '('  read    ')'   { $$ = $2; }
    |   '('  def     ')'   { $$ = $2; $$->code = genCode($$, NIL_EXP, NULL, NULL); }
    |   '('  defn    ')'   { $$ = $2; $$->code = genCode($$, NIL_EXP, NULL, NULL); }
    ;

command:
    opr factor factor
    {
        char* opr = (char*) strdup($1);
        $$ = createNode(opr, $2, $3);

        if (!strcmp(opr, "(+)")) {

            $$->code = genCode($$, ADD_EXP, $2->code->cur_instruction, $3->code->cur_instruction);

        } else if (!strcmp(opr, "(-)")) {

            $$->code = genCode($$, SUB_EXP, $2->code->cur_instruction, $3->code->cur_instruction);
        
        } else if (!strcmp(opr, "(*)")) {

            $$->code = genCode($$, MUL_EXP, $2->code->cur_instruction, $3->code->cur_instruction);

        } else if (!strcmp(opr, "(/)")) {

            $$->code = genCode($$, DIV_EXP, $2->code->cur_instruction, $3->code->cur_instruction);

        }
    }
    
    | ATOM '(' compound_factor ')'
    {
        $$ = createNode($1->label, $3, NULL);

        $1->code = genCode($1, ATOM_EXP, NULL, NULL);

        $$->code = genCode($$, INVOKE_EXP, $1->code->cur_instruction, $3->code->cur_instruction);
    }
    
    | IF expr '?' '(' command ')' '(' command ')'
    { 
        $$ = createNode("if", $2, createNode("then", $5, createNode("else", $8, NULL)));
        $$->code = (Program*) malloc(sizeof(Program));
        $$->code = genCode($2, IF_EXP, $5->code->cur_instruction, $8->code->cur_instruction);
    }
    
    | command '(' command ')'
    { 
        $$ = createNode("commandlist", $1, $3);
        $$->code = (Program*) malloc(sizeof(Program));
        $$->code = $1->code;
        $$->code->next_instruction = $3->code;
    }
    
    | list_iterator ATOM vector 
    { 
        $$ = createNode($1, createLeaf($2->label), $3);

        checkArity($2->label, 1);

        $2->code = genCode($2, ATOM_EXP, NULL, NULL);

        if (!strcmp($1, "map")) {

            $$->code = genCode($$, MAP_EXP, $2->code->cur_instruction, $3->code->cur_instruction);

        } else if (!strcmp($1, "filter")) {

            $$->code = genCode($$, FILTER_EXP, $2->code->cur_instruction, $3->code->cur_instruction);

        }
    }
    
    | list_op vector
    {
        $$ = createNode($1, $2, NULL);
        

        if (!strcmp($1, "head")) {

            $$->code = genCode($$, HEAD_EXP, $2->code->cur_instruction, NULL);

        } else if (!strcmp($1, "tail")) {

            $$->code = genCode($$, TAIL_EXP, $2->code->cur_instruction, NULL);

        } else if (!strcmp($1, "cons")) {

            $$->code = genCode($$, CONS_EXP, $2->code->cur_instruction, NULL);

        } else if (!strcmp($1, "count")) {

            $$->code = genCode($$, COUNT_EXP, $2->code->cur_instruction, NULL);

        }
    }
    
    | NIL
    {
        $$ = createLeaf("nil");
        $$->code = genCode($$, NIL_EXP, NULL, NULL);
    }
    ;

list_iterator:
    MAP
    {
        $$ = "map";
    }
    
    | FILTER
    {
        $$ = "filter";
    }
    ;

list_op:
    HEAD
    {
        $$ = "head";
    }
    
    | TAIL
    {
        $$ = "tail";
    }
    
    | CONS
    {
        $$ = "cons";
    }
    
    | COUNT
    {
        $$ = "count";
    }
    ;

write:
    WRITE '(' command ')'
    {
        $$ = createNode("write", $3, NULL);
    }
    ;

read:
    READ '(' command ')'
    {
        $$ = createNode("read", $3, NULL);
    }
    ;

defn:
    DEFN ATOM
    { 
        sym = (char*) strdup($2->label);
    }
    fnbody
    { 
        $$ = createNode("defn", createLeaf($2->label), $4);
    }
    ;

fnbody:
    '(' vector '(' command ')' ')' '(' fnbody ')'
    { 
        snprintf(anotation, 60, "aridade->%d", $2->params);
        $$ = createNode("multfnbody", createAnotatedNode("fnbody", $2, $4, anotation), $8);
        addAtom(createFnAtom(sym, $2->params));
    }
    
    | vector '(' command ')'
    { 
        snprintf(anotation, 60, "aridade->%d", $1->params);
        ($$) = (Tree*) createAnotatedNode("fnbody", $1, $3, anotation);
        addAtom(createFnAtom(sym, $1->params));
    }
    ;

def:
    DEF ATOM factor
    {
        $$ = createNode("def", createLeaf($2->label), $3);
    }
    
    | DEF ATOM vector
    {
        $$ = createNode("def", createLeaf($2->label), $3); printf("ARIDADE: %d\n", $3->params);
    }
    ;

vector:
    '[' element ']'
    {
        $$ = (Tree*) malloc(sizeof(Tree));
        $$ = (Tree*) $2;
        $$->code = genCode($2, VECTOR_EXP, NULL, NULL);
        $$->params = arity;
        arity = 0;
    }
    ;

element:
    term
    { 
        $$ = createNode("element", createLeaf($1->label), NULL);
        arity += 1;
        $$->code = (Program*) malloc(sizeof(Program));
        $$->code->cur_instruction = (Instruction*) malloc(sizeof(Instruction));
        $$->code->cur_instruction->exp.vector = (Program*) malloc(sizeof(Program));
        $$->code->cur_instruction->exp.vector->cur_instruction = $1->code->cur_instruction;
        $$->code->cur_instruction->exp.vector->next_instruction = NULL;
    }
    
    | term element
    { 
        $$ = createNode("element", createLeaf($1->label), $2);
        arity += 1;
        $$->code = (Program*) malloc(sizeof(Program));
        $$->code->cur_instruction = (Instruction*) malloc(sizeof(Instruction));
        $$->code->cur_instruction->exp.vector = (Program*) malloc(sizeof(Program));
        $$->code->cur_instruction->exp.vector->cur_instruction = $1->code->cur_instruction;
        $$->code->cur_instruction->exp.vector->next_instruction = $2->code;
    }
    ;

compound_factor:
    factor
    {
        $$ = createLeaf($1->label);
    }

    | factor ',' compound_factor
    {
        $$ = createNode("factor", createLeaf($1->label), $3);
        $$->code = $1->code;
        $$->code->next_instruction = $3->code;
    }
    ;

factor:
    term
    {
        $$ = createLeaf($1->label);
        $$->code = $1->code;
    }

    | '(' command ')'
    {
        $$ = $2;
        $$->code = $2->code;
    }
    ;

term:
    ATOM
    {
        $1->code = genCode($1, ATOM_EXP, NULL, NULL);
        $$ = $1;
        $1 = NULL;
        free($1);
    }
    
    | NUM
    {
        $1->code = genCode($1, INT_EXP, NULL, NULL);
        $$ = $1;
        $1 = NULL;
        free($1);
    }
    ;

expr:
    '(' log_opr factor factor ')'
    {
        $$ = createNode($2, $3, $4);

        if(!strcmp($2, "<=")) {

            $$->code = genCode($$, LOEQ_EXP, $3->code->cur_instruction, $4->code->cur_instruction);

        } else if(!strcmp($2, ">=")) {

            $$->code = genCode($$, GOEQ_EXP, $3->code->cur_instruction, $4->code->cur_instruction);
        
        } else if(!strcmp($2, ">")) {

            $$->code = genCode($$, GT_EXP, $3->code->cur_instruction, $4->code->cur_instruction);

        } else if(!strcmp($2, "<")) {

            $$->code = genCode($$, LT_EXP, $3->code->cur_instruction, $4->code->cur_instruction);

        } else if(!strcmp($2, "=")) {

            $$->code = genCode($$, EQ_EXP, $3->code->cur_instruction, $4->code->cur_instruction);

        } else if(!strcmp($2, "!=")) {

            $$->code = genCode($$, NEQ_EXP, $3->code->cur_instruction, $4->code->cur_instruction);
        
        }
        
    }
    
    | '(' NOT expr ')'
    {
        $$ = createNode("not", $3, NULL);
        $$->code = genCode($$, NOT_EXP, $3->code->cur_instruction, NULL);
    }
    ;

opr:
    '+'
    {
        $$ = "(+)";
    }
    
    | '-'
    {
        $$ = "(-)";
    }
    
    | '*'
    {
        $$ = "(*)";
    }
    
    | '/'
    {
        $$ = "(/)";
    }
    ;

log_opr:
    LOGOPR
    {
        $$ = $1;
    }
    
    | COMPLOGOPR
    {
        $$ = $1;
    }
    ;

%%

int main(int argc, char* argv[]) {
    if (argc == 1) {
        PRINT_COLOR(KRED);
        printf("No input file\n");
        PRINT_COLOR(KNRM);
        return -1;
    }

    yyin = fopen(argv[1], "r");

    if(yyin == NULL) {
        PRINT_COLOR(KRED);
        printf("No such file or directory\n");
        PRINT_COLOR(KNRM);
        exit(0);
    }

    if (argc == 3) {
        if(!strcmp(argv[2], "--lex")){
            lex = TRUE;
        } else if(!strcmp(argv[2], "--syntax")) {
            syntax = TRUE;
        }
    }

    if (argc == 4) {
        if(!strcmp(argv[2], "--lex")){
            lex = TRUE;
            printf("TOKENS: \n\n");
        } else if(!strcmp(argv[2], "--syntax")) {
            syntax = TRUE;
        }

        if(!strcmp(argv[3], "--syntax")){
            syntax = TRUE;
        } else if(!strcmp(argv[3], "--lex") && syntax) {
            lex = TRUE;
            printf("TOKENS: \n\n");
        }
    } 

    if (!yyparse()) {
        if (!errorList) {
            PRINT_COLOR(KGRN);
            printf("\nFile parsed correctly\n");
            PRINT_COLOR(KNRM);
        } else {
            printf("\n\n");
            PRINT_COLOR(KYEL);
            printErrors(&errorList);
            PRINT_COLOR(KNRM);    
        }
    } else {
        printf("\n\n");
        PRINT_COLOR(KYEL);
        printErrors(&errorList);
        PRINT_COLOR(KNRM);
    }

    fclose(yyin);
    
    return 0;
}

int yyerror (char *s) {
    char errorMessage[400];
    snprintf(errorMessage, 400, "\n%s at line { %d }, column { %d }\n", s, lines, characters);
    pushError(&errorList, errorMessage);
    return 0;
}

void pushError(error **list, char *errorName) {
	error *aux = (error*) malloc(sizeof(error));
	strcpy(aux->errorMsg, errorName);
	aux->next = (*list);
	(*list) = aux;
    aux = NULL;
    free(aux);
}

void printErrors(error **list) {
	error *aux = *list;
	while(aux!= NULL){		
		printf("%s\n", aux->errorMsg);
		aux = aux->next;
	}
	printf("\n");
}

Tree* createNode(char* label, Tree* left, Tree* right) {
    Tree* node = (Tree*) malloc(sizeof(Tree));
    strcpy(node->label, label);
    node->left = left;
    node->right = right;
    strcpy(node->attrs, "");
    return node;
}

Tree* createAnotatedNode(char* label, Tree* left, Tree* right, char* attrs) {
    Tree* node = (Tree*) malloc(sizeof(Tree));
    strcpy(node->label, label);
    node->left = left;
    node->right = right;
    strcpy(node->attrs, attrs);
    return node;
}

Tree* createLeaf(char* label) {
    return createNode(label, NULL, NULL);
}

Program* genCode(Tree* node, Type type, Instruction *lhs, Instruction *rhs) {
    Program *code = (Program*) malloc(sizeof(Program));
    code->cur_instruction = (Instruction*) malloc(sizeof(Instruction));
    code->cur_instruction->type = type;
    code->next_instruction = NULL;

    switch (type)
    {
        case NIL_EXP:
            code->cur_instruction->exp.nil = TRUE;
            return code;
        
        case INT_EXP:
            code->cur_instruction->exp.int_value = atoi(node->label);
            return code; 

        case VECTOR_EXP:
            code->cur_instruction->exp.vector = (Program*) malloc(sizeof(Program));
            code->cur_instruction->exp.vector = node->code;
            return code;
        
        case ATOM_EXP:
            code->cur_instruction->exp.atom = (char*) strdup(node->label);
            return code;
        
        case INVOKE_EXP:
            code->cur_instruction->exp.invoke = (Invoke*) malloc(sizeof(Invoke));
            code->cur_instruction->exp.invoke->atom = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.invoke->atom = lhs;
            code->cur_instruction->exp.invoke->params = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.invoke->params = rhs;
            return code;
        
        case ADD_EXP:
            // code->cur_instruction->exp.add = (Add*) malloc(sizeof(Add));
            // code->cur_instruction->exp.add->lhs = (Instruction*) malloc(sizeof(Instruction));
            // code->cur_instruction->exp.add->lhs = lhs;
            // code->cur_instruction->exp.add->rhs = (Instruction*) malloc(sizeof(Instruction));
            // code->cur_instruction->exp.add->rhs = rhs;
            return code;
        
        case SUB_EXP:
            code->cur_instruction->exp.sub = (Sub*) malloc(sizeof(Sub));
            code->cur_instruction->exp.sub->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.sub->lhs = lhs;
            code->cur_instruction->exp.sub->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.sub->rhs = rhs;
            return code;
        
        case MUL_EXP:
            code->cur_instruction->exp.mul = (Mul*) malloc(sizeof(Mul));
            code->cur_instruction->exp.mul->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.mul->lhs = lhs;
            code->cur_instruction->exp.mul->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.mul->rhs = rhs;
            return code;
        
        case DIV_EXP:
            code->cur_instruction->exp.div = (Div*) malloc(sizeof(Div));
            code->cur_instruction->exp.div->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.div->lhs = lhs;
            code->cur_instruction->exp.div->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.div->rhs = rhs;
            return code;
        
        case AND_EXP:
            code->cur_instruction->exp.and = (And*) malloc(sizeof(And));
            code->cur_instruction->exp.and->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.and->lhs = lhs;
            code->cur_instruction->exp.and->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.and->rhs = rhs;
            return code;
        
        case OR_EXP:
            code->cur_instruction->exp.or = (Or*) malloc(sizeof(Or));
            code->cur_instruction->exp.or->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.or->lhs = lhs;
            code->cur_instruction->exp.or->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.or->rhs = rhs;
            return code;
        
        case NOT_EXP:
            code->cur_instruction->exp.not = (Not*) malloc(sizeof(Not));
            code->cur_instruction->exp.not->instruction = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.not->instruction = lhs;
            return code;
        
        case GT_EXP:
            code->cur_instruction->exp.gt = (Gt*) malloc(sizeof(Gt));
            code->cur_instruction->exp.gt->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.gt->lhs = lhs;
            code->cur_instruction->exp.gt->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.gt->rhs = rhs;
            return code;
        
        case LT_EXP:
            code->cur_instruction->exp.lt = (Lt*) malloc(sizeof(Lt));
            code->cur_instruction->exp.lt->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.lt->lhs = lhs;
            code->cur_instruction->exp.lt->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.lt->rhs = rhs;
            return code;
        
        case GOEQ_EXP:
            code->cur_instruction->exp.goeq = (Goeq*) malloc(sizeof(Goeq));
            code->cur_instruction->exp.goeq->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.goeq->lhs = lhs;
            code->cur_instruction->exp.goeq->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.goeq->rhs = rhs;
            return code;
        
        case LOEQ_EXP:
            code->cur_instruction->exp.loeq = (Loeq*) malloc(sizeof(Loeq));
            code->cur_instruction->exp.loeq->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.loeq->lhs = lhs;
            code->cur_instruction->exp.loeq->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.loeq->rhs = rhs;
            return code;
        
        case EQ_EXP:
            code->cur_instruction->exp.eq = (Eq*) malloc(sizeof(Eq));
            code->cur_instruction->exp.eq->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.eq->lhs = lhs;
            code->cur_instruction->exp.eq->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.eq->rhs = rhs;
            return code;
        
        case NEQ_EXP:
            code->cur_instruction->exp.neq = (Neq*) malloc(sizeof(Neq));
            code->cur_instruction->exp.neq->lhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.neq->lhs = lhs;
            code->cur_instruction->exp.neq->rhs = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.neq->rhs = rhs;
            return code;
        
        case HEAD_EXP:
            code->cur_instruction->exp.head = (Head*) malloc(sizeof(Head));
            code->cur_instruction->exp.head->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.head->vector = lhs;
            return code;
        
        case TAIL_EXP:
            code->cur_instruction->exp.tail = (Tail*) malloc(sizeof(Tail));
            code->cur_instruction->exp.tail->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.tail->vector = lhs;
            return code;
        
        case CONS_EXP:
            code->cur_instruction->exp.cons = (Cons*) malloc(sizeof(Cons));
            code->cur_instruction->exp.cons->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.cons->vector = lhs;
            return code;
        
        case COUNT_EXP:
            code->cur_instruction->exp.count = (Count*) malloc(sizeof(Count));
            code->cur_instruction->exp.count->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.count->vector = lhs;
            return code;
        
        case MAP_EXP:
            code->cur_instruction->exp.map = (Map*) malloc(sizeof(Map));
            code->cur_instruction->exp.map->atom = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.map->atom = lhs;
            code->cur_instruction->exp.map->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.map->vector = rhs;
            return code;
        
        case FILTER_EXP:
            code->cur_instruction->exp.filter = (Filter*) malloc(sizeof(Filter));
            code->cur_instruction->exp.filter->atom = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.filter->atom = lhs;
            code->cur_instruction->exp.filter->vector = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.filter->vector = rhs;
            return code;

        case IF_EXP:
            code->cur_instruction->exp.ifstmt = (IfStmt*) malloc(sizeof(IfStmt));
            code->cur_instruction->exp.ifstmt->cond = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.ifstmt->cond = node->code->cur_instruction;
            code->cur_instruction->exp.ifstmt->ifStmt = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.ifstmt->ifStmt = lhs;
            code->cur_instruction->exp.ifstmt->elseStmt = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.ifstmt->elseStmt = rhs;
            return code;
        
        case WRITE_EXP:
            code->cur_instruction->exp.write = (Write*) malloc(sizeof(Write));
            code->cur_instruction->exp.write->instruction = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.write->instruction = lhs;
            return code;
        
        case READ_EXP:
            code->cur_instruction->exp.read = (Read*) malloc(sizeof(Read));
            code->cur_instruction->exp.read->instruction = (Instruction*) malloc(sizeof(Instruction));
            code->cur_instruction->exp.read->instruction = lhs;
            return code;  
        
        default:
            return NULL;
    }
}

void printTree(Tree* tree, int space) {
    int i;
    if(tree == NULL) { return; }
    space += 10;  

    printTree(tree->right, space);  
    tree->right = NULL;
    free(tree->right);
    if(syntax) { printf("\n"); }
    for (i = 10; i < space; i++)  { if(syntax) printf(" "); }  
    if(syntax) { printNode(tree); }
    printTree(tree->left, space);
    tree->left = NULL;
    free(tree->left);
    tree = NULL;
    free(tree);
}

void printNode(Tree* node) {
    printf("%s", node->label);
    if(strcmp(node->attrs,"")) printf(": %s", node->attrs);
    printf("\n");
}
