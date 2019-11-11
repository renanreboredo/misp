all: analise

analise: bison flex misp

analise-dev: bison-dev flex misp-dev

bison: syntax.y
	bison -d syntax.y

bison-dev: syntax.y
	bison -d syntax.y --report=all

flex:
	flex parser.l

misp:
	gcc syntax.tab.c lex.yy.c -o misp

misp-dev:
	gcc -Wall -W syntax.tab.c lex.yy.c -o misp

test-all-dev:
	./misp correto.misp --lex --syntax
	./misp correto2.misp --lex --syntax
	./misp correto3.misp --lex --syntax
	./misp errado.misp --lex --syntax
	./misp errado2.misp --lex --syntax

test-all:
	./misp correto.misp
	./misp correto2.misp
	./misp errado.misp
	./misp errado2.misp