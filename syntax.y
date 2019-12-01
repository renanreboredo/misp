%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "uthash.h"
#include "interpreter.h"
#include "util.h"

#define TRUE 1
#define FALSE 0

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
        Program *subroutine;
        int value;
        int *vector;
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
%type <node> term vector factor command program statements statement write read def defn fnbody element expr

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
    }
    ;

statement:
        '('  command ')'   { $$ = $2; }
    |   '('  write   ')'   { $$ = $2; }
    |   '('  read    ')'   { $$ = $2; }
    |   '('  def     ')'   { $$ = $2; }
    |   '('  defn    ')'   { $$ = $2; }
    ;

command:
    opr factor factor
    {
        $$ = createNode((char*) strdup($1), $2, $3);
    }
    
    | ATOM factor factor
    {
        $$ = createNode($1->label, $2, $3);
    }
    
    | IF expr '?' '(' command ')' '(' command ')'
    { 
        $$ = createNode("if", $2, createNode("then", $5, createNode("else", $8, NULL)));
    }
    
    | command '(' command ')'
    { 
        $$ = createNode("commandlist", $1, $3);
    }
    
    | list_iterator ATOM vector 
    { 
        $$ = createNode($1, createLeaf($2->label), $3);
        checkArity($2->label, 1);
    }
    
    | list_op vector
    {
        $$ = createNode($1, $2, NULL);
    }
    
    | NIL
    {
        $$ = createLeaf("nil");
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
        $$->params = arity; arity = 0;
    }
    ;

element:
    term
    { 
        $$ = createNode("element", createLeaf($1->label), NULL);
        arity += 1;
    }
    
    | term element
    { 
        $$ = createNode("element", createLeaf($1->label), $2);
        arity += 1;
    }
    ;

factor:
    term
    {
        $$ = createLeaf($1->label);
    }
    
    | '(' command ')'
    {
        $$ = $2;
    }
    ;

term:
    ATOM
    {
        $$ = $1;
    }
    
    | NUM
    {
        $$ = $1;
    }
    ;

expr:
    '(' log_opr factor factor ')'
    {
        $$ = createNode($2, $3, $4);
    }
    
    | '(' NOT expr ')'
    {
        $$ = createNode("not", $3, NULL);
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

int yyerror (char *s)
{
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
