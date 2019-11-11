## Versões das ferramentas

Versões das bibliotecas e sistema operacional utilizados no projeto:
flex: 2.6.4
bison: (GNU Bison) 3.0.4
gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0
OS: Ubuntu 18.04.3 LTS

## Rodando o projeto

Para rodar o projeto, basta rodar 

```sh
make 
make test-all
```

que irá realizar o build do projeto e rodar os testes disponíveis. Para rodar cada entrada separadamente basta rodar:

```sh
make
./misp <arquivo-de-entrada>.misp
```


Caso deseje que o programa gere informações mais detalhadas de saída, como os tokens lidos, a tabela de símbolos e a AST gerados, bem como informações de debug do bison e flex, basta rodar:
```sh
make analise-dev
make test-all-dev
```

Para rodar cada entrada separadamente, é necessário rodar o comando ./misp passando as flags --lex e --syntax, da seguinte forma:

```sh
make analise-dev
./misp <arquivo-de-entrada>.misp --lex --syntax
```