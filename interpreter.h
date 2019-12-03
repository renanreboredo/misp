#include "util.h"
#include "uthash.h"

typedef struct Program Program;
typedef struct Context Context;
typedef struct Instruction Instruction;
typedef struct Invoke Invoke;
typedef struct Add Add;
typedef struct Sub Sub;
typedef struct Mul Mul;
typedef struct Div Div;
typedef struct And And;
typedef struct Or Or;
typedef struct Not Not;
typedef struct Gt Gt;
typedef struct Lt Lt;
typedef struct Goeq Goeq;
typedef struct Loeq Loeq;
typedef struct Eq Eq;
typedef struct Neq Neq;
typedef struct Map Map;
typedef struct Filter Filter;
typedef struct Head Head;
typedef struct Tail Tail;
typedef struct Cons Cons;
typedef struct Count Count;
typedef struct Filter Filter;
typedef struct IfStmt IfStmt;
typedef struct Write Write;
typedef struct Read Read;

struct Invoke {
    Instruction *atom;
    Instruction *params;
};

typedef struct Add {
    Instruction *lhs;
    Instruction *rhs;
} Add;

typedef struct Sub {
    Instruction *lhs;
    Instruction *rhs;
} Sub;

typedef struct Mul {
    Instruction *lhs;
    Instruction *rhs;
} Mul;

typedef struct Div {
    Instruction *lhs;
    Instruction *rhs;
} Div;

typedef struct And {
    Instruction *lhs;
    Instruction *rhs;
} And;

typedef struct Or {
    Instruction *lhs;
    Instruction *rhs;
} Or;

typedef struct Not {
    Instruction *instruction;
} Not;

typedef struct Gt {
    Instruction *lhs;
    Instruction *rhs;
} Gt;

typedef struct Lt {
    Instruction *lhs;
    Instruction *rhs;
} Lt;

typedef struct Goeq {
    Instruction *lhs;
    Instruction *rhs;
} Goeq;

typedef struct Loeq {
    Instruction *lhs;
    Instruction *rhs;
} Loeq;

typedef struct Eq {
    Instruction *lhs;
    Instruction *rhs;
} Eq;

typedef struct Neq {
    Instruction *lhs;
    Instruction *rhs;
} Neq;

typedef struct Write {
    Instruction *instruction;
} Write;

typedef struct Read {
    Instruction *instruction;
} Read;

typedef struct IfStmt {
    Instruction *cond;
    Instruction *ifStmt;
    Instruction *elseStmt;
} IfStmt;

typedef struct Map {
    Instruction *atom;
    Instruction *vector;
} Map;

typedef struct Filter {
    Instruction *atom;
    Instruction *vector;
} Filter;

typedef struct Head {
    Instruction *vector;
} Head;

typedef struct Tail {
    Instruction *vector;
} Tail;

typedef struct Cons {
    Instruction *vector;
} Cons;

typedef struct Count {
    Instruction *vector;
} Count;

typedef enum Type {
    NIL_EXP,
    INT_EXP,
    VECTOR_EXP,
    ATOM_EXP,
    INVOKE_EXP,
    ADD_EXP,
    SUB_EXP,
    MUL_EXP,
    DIV_EXP,
    AND_EXP,
    OR_EXP,
    NOT_EXP,
    GT_EXP,
    LT_EXP,
    GOEQ_EXP,
    LOEQ_EXP,
    EQ_EXP,
    NEQ_EXP,
    HEAD_EXP,
    TAIL_EXP,
    CONS_EXP,
    COUNT_EXP,
    MAP_EXP,
    FILTER_EXP,
    IF_EXP,
    WRITE_EXP,
    READ_EXP,
} Type;

struct Instruction {
    Type type;
    union Expression {
        Bool            nil;
        int             int_value;
        Program         *vector;
        char            *atom;
        Invoke          *invoke;
        Add             *add;
        Sub             *sub;
        Mul             *mul;
        Div             *div;
        And             *and;
        Or              *or;
        Not             *not;
        Gt              *gt;
        Lt              *lt;
        Goeq            *goeq;
        Loeq            *loeq;
        Eq              *eq;
        Neq             *neq;
        Head            *head;
        Tail            *tail;
        Cons            *cons;
        Count           *count;
        Map             *map;
        Filter          *filter;
        IfStmt          *ifstmt;
        Write           *write;
        Read            *read;
    } exp;
};

typedef struct Program {
    Instruction *cur_instruction;
    Program *next_instruction;
} Program;

typedef struct Context {
    int id;
    char atom[60];
    UT_hash_handle handler;
} Context;

Program *program;

// INSTRUCTION EXECUTION FUNCTIONS

Context*           nil_exec     ( Instruction *instruction, Context *context );
Context*     int_value_exec     ( Instruction *instruction, Context *context );
Context*    int_vector_exec     ( Instruction *instruction, Context *context );
Context*          atom_exec     ( Instruction *instruction, Context *context );
Context*        invoke_exec     ( Instruction *instruction, Context *context );
Context*           add_exec     ( Instruction *instruction, Context *context );
Context*           sub_exec     ( Instruction *instruction, Context *context );
Context*           mul_exec     ( Instruction *instruction, Context *context );
Context*           div_exec     ( Instruction *instruction, Context *context );
Context*           and_exec     ( Instruction *instruction, Context *context );
Context*            or_exec     ( Instruction *instruction, Context *context );
Context*           not_exec     ( Instruction *instruction, Context *context );
Context*            gt_exec     ( Instruction *instruction, Context *context );
Context*            lt_exec     ( Instruction *instruction, Context *context );
Context*          goeq_exec     ( Instruction *instruction, Context *context );
Context*          loeq_exec     ( Instruction *instruction, Context *context );
Context*            eq_exec     ( Instruction *instruction, Context *context );
Context*           neq_exec     ( Instruction *instruction, Context *context );
Context*          head_exec     ( Instruction *instruction, Context *context );
Context*          tail_exec     ( Instruction *instruction, Context *context );
Context*          cons_exec     ( Instruction *instruction, Context *context );
Context*         count_exec     ( Instruction *instruction, Context *context );
Context*           map_exec     ( Instruction *instruction, Context *context );
Context*        filter_exec     ( Instruction *instruction, Context *context );
Context*        ifstmt_exec     ( Instruction *instruction, Context *context );
Context*         write_exec     ( Instruction *instruction, Context *context );
Context*          read_exec     ( Instruction *instruction, Context *context );
Context*   exec_instruction     ( Instruction *instruction, Context *context );


void run ( Program *program, Context *context );