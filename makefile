all: analise-dev

analise: bison flex misp

analise-dev: bison-dev flex misp-dev

bison: syntax.y
	bison syntax.y

bison-dev: syntax.y
	bison -d syntax.y --report=all

flex:
	flex parser.l

misp:
	gcc parser.c -lfl -o misp

misp-dev:
	gcc -Wall -W syntax.tab.c lex.yy.c -o misp

test-all-dev:
	./misp correto.misp --tokens
	./misp correto2.misp --tokens
	./misp errado.misp --tokens
	./misp errado2.misp --tokens

test-all:
	./misp correto.misp
	./misp correto2.misp
	./misp errado.misp
	./misp errado2.misp