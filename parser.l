%{
  #include<stdio.h>
  #include<stdlib.h>
  #include<string.h>
  #define TRUE 1
  #define FALSE 0
  #define KNRM  "\x1B[0m"
  #define KRED  "\x1B[31m"
  #define KGRN  "\x1B[32m"
  #define KYEL  "\x1B[33m"

  int debug = FALSE;
  int errors = FALSE;
  int lines = 1;
  int characters = 0;

  enum token {
    LSSTART = 1,
    LSEND,
    VECTORSTART,
    VECTOREND,
    MAP,
    FILTER,
    DEFN,
    DEF,
    ATOM,
    COUNT,
    HEAD,
    TAIL,
    NIL,
    NUM,
    NOT,
    OPR,
    LOGOPR,
    COMPLOGOPR,
    READ,
    WRITE,
    IF,
  };

  typedef struct error {
	  char errorMsg[400];
	  struct error* next;
  } error;

  void printToken(char* token) {
    if(debug) printf("%s  ", token);   
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

  void throwError(char* tkn);

  int characterCount(char* parsedString);

  void pushError(error **list, char *errorName);
  
  void printErrors(error **list);

  error *errorList = (error*)0; 
%}

%x COMMENT

%%

";"                           BEGIN(COMMENT);
<COMMENT>\n                   printToken("\n");    BEGIN(INITIAL);
<COMMENT>.                    ;


([0-9]{1,})((\.)?[0-9]{1,})?  characters += characterCount(yytext);     printToken("NUM");            return NUM;
"("                           characters += characterCount(yytext);     printToken("LSSTART");        return LSSTART;
")"                           characters += characterCount(yytext);     printToken("LSEND");          return LSEND;
"["                           characters += characterCount(yytext);     printToken("VECTORSTART");    return LSSTART;
"]"                           characters += characterCount(yytext);     printToken("VECTOREND");      return LSEND;
"defn"                        characters += characterCount(yytext);     printToken("DEFN");           return DEFN;
"def"                         characters += characterCount(yytext);     printToken("DEFN");           return DEFN;
"map"                         characters += characterCount(yytext);     printToken("MAP");            return MAP;
"filter"                      characters += characterCount(yytext);     printToken("FILTER");         return FILTER;
"count"                       characters += characterCount(yytext);     printToken("COUNT");          return COUNT;
"head"                        characters += characterCount(yytext);     printToken("HEAD");           return HEAD;
"tail"                        characters += characterCount(yytext);     printToken("TAIL");           return TAIL;
"if"                          characters += characterCount(yytext);     printToken("IF");             return IF;
"read"                        characters += characterCount(yytext);     printToken("READ");           return READ;
"write"                       characters += characterCount(yytext);     printToken("WRITE");          return WRITE;
"nil"                         characters += characterCount(yytext);     printToken("NIL");            return NIL;
"not"                         characters += characterCount(yytext);     printToken("NOT");            return NOT;
"+"|"-"|"*"|"/"               characters += characterCount(yytext);     printToken("OPR");            return OPR;
"<="|">="|"!="                characters += characterCount(yytext);     printToken("COMPLOGOPR");     return COMPLOGOPR; 
"="|"<"|">"                   characters += characterCount(yytext);     printToken("LOGOPR");         return LOGOPR;
[a-zA-Z][a-zA-Z0-9]*          characters += characterCount(yytext);     printToken("ATOM");           return ATOM;
"\n"                          characters = 0;                           printToken("\n");             lines++;
"?"                           characters += characterCount(yytext); 
[ \t]+                        characters += characterCount(yytext); 
.                             characters += characterCount(yytext);     throwError(yytext);           errors = TRUE;

%%

int main(int argc, char* argv[]) {
    enum token tkn;
    
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
      if(!strcmp(argv[2], "--debug")){
        debug = TRUE;
      }
    } 

    while((tkn = yylex()));
    
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
    return 0;
}

int characterCount(char* parsedString) {
  return strlen(parsedString);
}

void throwError(char* tkn) {
  char errorMessage[400];
  
  snprintf(errorMessage, 400, ">> token \"%s\" not recognized\n", tkn);
  pushError(&errorList, errorMessage);
  
  snprintf(errorMessage, 400, "Lexical error at line { %d }, column { %d }\n", lines, characters);
  pushError(&errorList, errorMessage);
}

void pushError(error **list, char *errorName) {
	error *aux = (error*) malloc(sizeof(error));
	strcpy(aux->errorMsg, errorName);
	aux->next = (*list);
	(*list) = aux;
}

void printErrors(error **list) {
	error *aux = *list;
	while(aux!= NULL){		
		printf("%s\n", aux->errorMsg);
		aux = aux->next;
	}
	printf("\n");
}