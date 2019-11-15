all: analise

analise: bison flex misp-prd

analise-dev: bison-dev flex misp-dev

bison: syntax.y
	bison -d syntax.y

bison-dev: syntax.y
	bison -d -g syntax.y --report=all

flex:
	flex parser.l

misp-prd:
	gcc syntax.tab.c lex.yy.c -o misp

misp-dev:
	gcc -Wall -W syntax.tab.c lex.yy.c -o misp

test-all-dev:
	./misp correto.misp --lex --syntax
	./misp correto2.misp --lex --syntax
	./misp correto3.misp --lex --syntax
	./misp errado.misp --lex --syntax
	./misp errado2.misp --lex --syntax
	./misp errado3.misp --lex --syntax

test-all:
	./misp correto.misp
	./misp correto2.misp
	./misp correto3.misp
	./misp errado.misp
	./misp errado2.misp
	./misp errado3.misp

clean:
	rm -rf	syntax.tab.c lex.yy.c misp syntax.tab.h