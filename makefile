all: analise

analise: flex parser

analise-dev: flex parser-dev

flex:
	flex -o parser.c parser.l

parser:
	gcc parser.c -lfl -o misp

parser-dev:
	gcc -Wall -W parser.c -lfl -o misp

test-all-dev:
	./misp correto.misp --debug
	./misp correto2.misp --debug
	./misp errado.misp --debug
	./misp errado2.misp --debug

test-all:
	./misp correto.misp
	./misp correto2.misp
	./misp errado.misp
	./misp errado2.misp