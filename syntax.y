%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "uthash.h"

#define TRUE 1
#define FALSE 0

#define YYDEBUG TRUE

#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KGRN  "\x1B[32m"
#define KYEL  "\x1B[33m"
#define KBLU  "\x1B[34m"
#define KMAG  "\x1B[35m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"

extern int yydebug;
extern FILE *yyin;
int yyerror (char *s);
int yylex ();

typedef struct tree {
    char label[50];
    struct tree *left;
    struct tree *right;
} Tree;

typedef struct attr {
    struct tree *node;
    int params;
} Attr;

typedef struct symbol {
    char atom[50];
    int id;
    UT_hash_handle hh;
} Symbol;

typedef struct error {
    char errorMsg[400];
    struct error* next;
} error;

int lines = 1;
int arity = 0;
int characters = 0;
error *errors= (error*)0;
int lex = FALSE;
int syntax = FALSE;
int hasSymbols = FALSE;

Tree* AST = NULL;
Symbol* symbolTable = NULL;
int symbolID = 0;

void throwError(char* tkn);

void pushError(error **list, char *errorName);

void printErrors(error **list);

error *errorList = (error*)0;

Tree* createNode(char* label, Tree* left, Tree* right);
Tree* createLeaf(char* label);
void printNode(Tree* node);
void printTree(Tree* tree, int space);

Symbol* findAtom(char* atom) {
    Symbol* s = (Symbol*) malloc(sizeof(Symbol));
    HASH_FIND_STR(symbolTable, atom, s);
    return s;
}

void addAtom(char* atom) {
    Symbol* s = (Symbol*) malloc(sizeof(Symbol));
    strcpy(s->atom, atom);
    s->id = symbolID++;
    HASH_ADD_STR(symbolTable, atom, s);
    if(!hasSymbols) { hasSymbols = TRUE; }
}


void printDelimiter() {
    printf("\n--------------------------------------------------------------------------\n\n");
}

void printSymbolTable() {
    if(hasSymbols) {
        Symbol *tmp = NULL;
        Symbol* s = (Symbol*) malloc(sizeof(Symbol));
        
        printDelimiter();
        printf("SYMBOL TABLE: \n\n");

        printf("|\tatom\t|\tid\t|\n\n");

        HASH_ITER(hh, symbolTable, s, tmp) {
            printf("|\t%s\t|\t%d\t|\n", s->atom, s->id);
            HASH_DEL(symbolTable, s);
            free(s);
        }
    } else return;
}

void printColorYellow(){
    printf("%s", KYEL);
};

void printColorGreen(){
    printf("%s", KGRN);
};

void printColorEnd(){
    printf("%s", KNRM);
};

%}
%union {
	char *val;
    char opr;
    struct tree *node;
    struct attr *synth;
}

%token MAP
%token FILTER
%token DEFN
%token DEF
%token <val> ATOM
%token COUNT
%token CONS
%token HEAD
%token TAIL
%token NIL
%token <val> NUM
%token NOT
%token <opr> OPR
%token <val> LOGOPR
%token <val> COMPLOGOPR
%token READ
%token WRITE
%token IF

%type <val> term list_iterator list_op log_opr opr
%type <node> factor command program statements statement write read def vector element defn fnbody expr
%type <synth> fnbody

%%

program: 
    /* empty */ { AST = NULL; }
    | statements { AST = $1; if(syntax) { printDelimiter(); printf("\n\nAST: \n\n"); printTree(AST, 0); printSymbolTable(); } }
    | error { AST = NULL; }
    ;

statements: 
    statement { $$ = $1; }
    | statement statements { $$ = createNode("statements", $1, $2); }
    ;

statement:
        '(' command ')'   { $$ = $2; }
    |   '(' write   ')'   { $$ = $2; }
    |   '(' read    ')'   { $$ = $2; }
    |   '(' def     ')'   { $$ = $2; }
    |   '(' defn    ')'   { $$ = $2; }
    ;

command:
    opr factor factor { $$ = createNode($1, $2, $3); }
    | ATOM factor factor { $$ = createNode($1, $2, $3); }
    | IF expr '?' '(' command ')' '(' command ')' { $$ = createNode("if", $2, createNode("then", $5, createNode("else", $8, NULL))); }
    | command '(' command ')' { $$ = createNode("commandlist", $1, $3); }
    | list_iterator ATOM vector { $$ = createNode($1, createLeaf($2), $3); }
    | list_op vector { $$ = createNode($1, $2, NULL); }
    | NIL { $$ = createLeaf("nil"); }
    ;

list_iterator:
    MAP         { $$ = "map"; }
    | FILTER    { $$ = "filter"; }
    ;

list_op:
    HEAD        { $$ = "head"; }
    | TAIL      { $$ = "tail"; }
    | CONS      { $$ = "cons"; }
    | COUNT     { $$ = "count"; }
    ;

write:
    WRITE '(' command ')' { $$ = createNode("write", $3, NULL); }
    ;

read:
    READ '(' command ')' { $$ = createNode("read", $3, NULL); }
    ;

defn:
    DEFN ATOM fnbody { $$ = createNode("defn", createLeaf($2), $3); }
    ;

fnbody:
    '(' vector '(' command ')' ')' '(' fnbody ')' { $$ = createNode("multfnbody", createNode("fnbody", $2, $4), $8); }
    | vector '(' command ')' { $$ = createNode("fnbody", $1, $3); }
    ;

def:
    DEF ATOM factor { $$ = createNode("def", createLeaf($2), $3); }
    | DEF ATOM vector { $$ = createNode("def", createLeaf($2), $3); }
    ;

vector:
    '[' element ']' { $$ = $2; }
    ;

element:
    term { $$ = createNode("element", createLeaf($1), NULL); }
    | term element { $$ = createNode("element", createLeaf($1), $2); }
    ;

factor:
    term { $$ = createLeaf($1); }
    | '(' command ')' { $$ = $2; }
    ;

term:
    ATOM { addAtom($1); $$ = $1; }
    | NUM { $$ = $1; }
    ;

expr:
    '(' log_opr factor factor ')' { $$ = createNode($2, $3, $4); }
    | '(' NOT expr ')' { $$ = createNode("not", $3, NULL); }
    ;

opr:
    '+'     { $$ = "(+)"; }
    | '-'   { $$ = "(-)"; }
    | '*'   { $$ = "(*)"; }
    | '/'   { $$ = "(/)"; }
    ;

log_opr:
    LOGOPR          { $$ = $1; }
    | COMPLOGOPR    { $$ = $1; }
    ;

%%

int main(int argc, char* argv[]) {
    if(argc == 1) {
      printf("No input files\n");
      exit(0);
    }

    yyin = fopen(argv[1], "r");

    if(yyin == NULL) {
        printf("No such file or directory\n");
        exit(0);
    }

    if(argc == 3) {
      if(!strcmp(argv[2], "--lex")){
        lex = TRUE;
      }
    }

    if(argc == 4) {
      if(!strcmp(argv[2], "--lex")){
        lex = TRUE;
        printf("TOKENS: \n");
      }

      if(!strcmp(argv[3], "--syntax")){
        syntax = TRUE;
      }
    } 

    if(!yyparse()) {
      if(!errors) {
        printColorGreen();
        printf("\nFile parsed correctly\n");
        printColorEnd();
      } else {
        printf("\n\n");
        printColorYellow();
        printErrors(&errorList);
        printColorEnd();    
      }
    } else {
      printf("\n\n");
      printColorYellow();
      printErrors(&errorList);
      printColorEnd();
    }
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
    return node;
}

Tree* createLeaf(char* label) {
    return createNode(label, NULL, NULL);
}

void printTree(Tree* tree, int space) {
    int i;
    if(syntax) {
        if(tree == NULL) { return; }
        space += 10;  
    
        printTree(tree->right, space);  
    	// tree->right = NULL;
	// free(tree->right);
        printf("\n");
        for (i = 10; i < space; i++)  { printf(" "); }  
        printNode(tree);
        printTree(tree->left, space);
	// tree->left = NULL;
	// free(tree->left);
	// tree = NULL;
	// free(tree);
    } else return;
}

void printNode(Tree* node) {
    printf("%s\n", node->label);
}
