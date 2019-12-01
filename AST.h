
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

typedef struct tree {
    char label[100];
    Tree *left;
    Tree *right;
    int aridade;
    Program *code;
    char attrs[100];
} Tree;