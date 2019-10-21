%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TRUE 1
#define FALSE 0

#define YYDEBUG TRUE
#define TYPECONVERSIONDEBUG FALSE

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

typedef struct symbol {
	char type[30];
	char name[200];
	int used;
	int address;
	struct symbol *next;
} symbol;

typedef struct error {
    char errorMsg[400];
    struct error* next;
} error;

char* currentType;
int typeConversion = FALSE;
int leftMostIsFloat = FALSE;
int lines = 1;
int characters = 0;
symbol *symbol_table = (symbol*)0;
error *errors= (error*)0;
error *warnings= (error*)0;
int address = 0;
int debug = FALSE;

void push_symbol(char* sym_name);
symbol* find_symbol(char *sym_name);

void throwError(char* tkn);

int characterCount(char* parsedString);

void pushError(error **list, char *errorName);

void printErrors(error **list);

error *errorList = (error*)0;

void printColorYellow(){
    printf("%s", KYEL);
};

void printColorGreen(){
    printf("%s", KGRN);
};

void printColorEnd(){
    printf("%s", KNRM);
};

void push_error(error **list, char* error_name);
void print_errors(error **list);
int list_length(error **list);

void print_symbol_table();
void push_symbol_table (char * sym_name);
void verify_variables_not_used();
void verify_symbol_table (char * sym_name);
void check_type_left_most (char * sym_name);
void check_type_conversion(char * sym_name);

%}
%union {
	char *atom;
	char *val;
	char opa;
}

%token MAP
%token FILTER
%token DEFN
%token DEF
%token ATOM
%token COUNT
%token CONS
%token HEAD
%token TAIL
%token NIL
%token NUM
%token NOT
%token OPR
%token LOGOPR
%token COMPLOGOPR
%token READ
%token WRITE
%token IF

%%

program: 
    /* empty */
    | statements
    ;

statements: 
    statement
    | statement statements
    ;

statement:
    '(' command ')'
    | '(' write ')'
    | '(' read ')'
    | '(' def ')'
    | '(' defn ')'
    ;

command:
    opr factor factor
    | ATOM factor factor
    | IF expr '?' '(' command ')' '(' command ')'
    | command '(' command ')'
    | list_iterator ATOM vector
    | list_op vector
    | NIL
    ;

list_iterator:
    MAP
    | FILTER
    ;

list_op:
    HEAD
    | TAIL
    | CONS
    | COUNT
    ;

write:
    WRITE command
    ;

read:
    READ command
    ;

defn:
    DEFN ATOM fnbody
    ;

fnbody:
    '(' vector '(' command ')' ')' '(' fnbody ')'
    | vector '(' command ')'
    ;

def:
    DEF ATOM factor
    | DEF ATOM vector
    ;

vector:
    '[' element ']'
    ;

element:
    term
    | term element
    ;

factor:
    term
    | '(' command ')'
    ;

term:
    ATOM
    | NUM
    ;

expr:
    '(' log_opr factor factor ')'
    | '(' NOT expr ')'
    ;

opr:
    '+'
    | '-'
    | '*'
    | '/'
    ;

log_opr:
    LOGOPR
    | COMPLOGOPR
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
      if(!strcmp(argv[2], "--tokens")){
        debug = TRUE;
      }
    } 

    if(!yyparse()) {
      printColorGreen();
      printf("\nFile parsed correctly\n");
      printColorEnd();
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
    printColorYellow();
	printf ("\n%s at line { %d }, column { %d }\n", s, lines, characters);
    printColorEnd();
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