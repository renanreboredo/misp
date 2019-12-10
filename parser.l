%{
  #include<stdio.h>
  #include<stdlib.h>
  #include<string.h>
  #include "syntax.tab.h"
  #include "interpreter.h"
  
  #define KNRM  "\x1B[0m"
  #define KRED  "\x1B[31m"
  #define KGRN  "\x1B[32m"
  #define KYEL  "\x1B[33m"

  extern int errors;
  extern int lex;
  extern int lines;
  extern int characters;
  typedef struct tree Tree;
  typedef struct tree {
    char label[100];
    Tree *left;
    Tree *right;
    int params;
    Program *code;
    char attrs[100];
  } Tree;

  typedef struct error {
	  char errorMsg[400];
	  struct error* next;
  } error;

  void printToken(char* token) {
    if(lex) printf("%s  ", token);   
  }

  extern void pushError(error **list, char* error_name);
  
  void throwLexicalError(char* tkn);

  int characterCount(char* parsedString);

  extern error *errorList; 
%}

%option noinput
%option nounput
%x COMMENT

%%

";"                           BEGIN(COMMENT);
<COMMENT>\n                   BEGIN(INITIAL);
<COMMENT>.                    ;


("-")?([0-9]{1,})((\.)?[0-9]{1,})?  characters += characterCount(yytext);     printToken("NUM");         yylval.node = (Tree*) malloc(sizeof(Tree));                  strcpy(yylval.node->label, (char*) strdup(yytext));          return NUM;
"("                           characters += characterCount(yytext);     printToken("(");                                                                        return yytext[0];
")"                           characters += characterCount(yytext);     printToken(")");                                                                        return yytext[0];
"["                           characters += characterCount(yytext);     printToken("[");                                                                        return yytext[0];
"]"                           characters += characterCount(yytext);     printToken("]");                                                                        return yytext[0];
"_"                           characters += characterCount(yytext);     printToken("_");                                                                        return yytext[0];
"defn"                        characters += characterCount(yytext);     printToken("DEFN");                                                                     return DEFN;
"def"                         characters += characterCount(yytext);     printToken("DEF");                                                                      return DEF;
"cons"                        characters += characterCount(yytext);     printToken("CONS");                                                                     return CONS;
"map"                         characters += characterCount(yytext);     printToken("MAP");                                                                      return MAP;
"filter"                      characters += characterCount(yytext);     printToken("FILTER");                                                                   return FILTER;
"count"                       characters += characterCount(yytext);     printToken("COUNT");                                                                    return COUNT;
"head"                        characters += characterCount(yytext);     printToken("HEAD");                                                                     return HEAD;
"tail"                        characters += characterCount(yytext);     printToken("TAIL");                                                                     return TAIL;
"if"                          characters += characterCount(yytext);     printToken("IF");                                                                       return IF;
"read"                        characters += characterCount(yytext);     printToken("READ");                                                                     return READ;
"write"                       characters += characterCount(yytext);     printToken("WRITE");                                                                    return WRITE;
"nil"                         characters += characterCount(yytext);     printToken("NIL");                                                                      return NIL;
"not"                         characters += characterCount(yytext);     printToken("NOT");                                                                      return NOT;
"+"|"-"|"*"|"/"               characters += characterCount(yytext);     printToken("OPR");                                                                      return yytext[0];
"<="|">="|"!="                characters += characterCount(yytext);     printToken("COMPLOGOPR");   yylval.val = (char*) strdup(yytext);                        return COMPLOGOPR; 
"="|"<"|">"                   characters += characterCount(yytext);     printToken("LOGOPR");       yylval.val = (char*) strdup(yytext);                        return LOGOPR;
[a-zA-Z][a-zA-Z0-9]*          characters += characterCount(yytext);     printToken("ATOM");         yylval.node = (Tree*) malloc(sizeof(Tree));                 strcpy(yylval.node->label, (char*) strdup(yytext));         return ATOM;
"\n"                          characters = 0;                           printToken("\n");                                                                       lines++;
"?"                           characters += characterCount(yytext);                                                                                             return yytext[0];
[ \t]+                        characters += characterCount(yytext); 
.                             characters += characterCount(yytext);     throwLexicalError(yytext);                                                              errors = TRUE;

%%

int yywrap() {
  return 1;
}

int characterCount(char* parsedString) {
  return strlen(parsedString);
}

void throwLexicalError(char* tkn) {
  char errorMessage[400];
  
  snprintf(errorMessage, 400, ">> token \"%s\" not recognized\n", tkn);
  pushError(&errorList, errorMessage);
  
  snprintf(errorMessage, 400, "lexical error at line { %d }, column { %d }\n", lines, characters);
  pushError(&errorList, errorMessage);
}