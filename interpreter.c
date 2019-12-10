#include "interpreter.h"
#include "syntax.tab.h"

void exec_instruction ( Instruction *instruction, Context *context) {
    switch (instruction->type)
    {
        case NIL_EXP:
            return nil_exec(instruction, context);
        
        case INT_EXP:
            return int_value_exec(instruction, context);

        case VECTOR_EXP:
            return int_vector_exec(instruction, context);
        
        case ATOM_EXP:
            return atom_exec(instruction, context);
        
        case INVOKE_EXP:
            return invoke_exec(instruction, context);
        
        case ADD_EXP:
            return add_exec(instruction, context);
        
        case SUB_EXP:
            return sub_exec(instruction, context);
        
        case MUL_EXP:
            return mul_exec(instruction, context);
        
        case DIV_EXP:
            return div_exec(instruction, context);
        
        case AND_EXP:
            return and_exec(instruction, context);
        
        case OR_EXP:
            return or_exec(instruction, context);
        
        case NOT_EXP:
            return not_exec(instruction, context);
        
        case GT_EXP:
            return gt_exec(instruction, context);
        
        case LT_EXP:
            return lt_exec(instruction, context);
        
        case GOEQ_EXP:
            return goeq_exec(instruction, context);
        
        case LOEQ_EXP:
            return loeq_exec(instruction, context);
        
        case EQ_EXP:
            return eq_exec(instruction, context);
        
        case NEQ_EXP:
            return neq_exec(instruction, context);
        
        case HEAD_EXP:
            return head_exec(instruction, context);
        
        case TAIL_EXP:
            return tail_exec(instruction, context);
        
        case CONS_EXP:
            return cons_exec(instruction, context);
        
        case COUNT_EXP:
            return count_exec(instruction, context);
        
        case MAP_EXP:
            return map_exec(instruction, context);
        
        case FILTER_EXP:
            return filter_exec(instruction, context);

        case IF_EXP:
            return ifstmt_exec(instruction, context);
        
        case WRITE_EXP:
            return write_exec(instruction, context);
        
        case READ_EXP:
            return read_exec(instruction, context);
        
        default:
            return;
    }
}

void nil_exec ( Instruction *instruction, Context *context ) {
    return;
}

void int_value_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO INT\n\n");
    context->result = instruction->exp.int_value;
    return;
}

void int_vector_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO VECTOR\n\n");
    return;
}

void atom_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO ATOM\n\n");
    Local *local = (Local*) malloc(sizeof(Local));
    contextoAtual = context;
    local = findParameter(instruction->exp.atom, (Context*) context);
    if (local != NULL) {
        context->result = local->value;
    } else {
        PRINT_COLOR(KRED);
        printf("ATOM COULD NOT BE FOUND!\n");
        PRINT_COLOR(KNRM);
        return;
    }
    return;
}

void invoke_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO INVOKE\n\n");
    int i;
    int result;
    char *atom;
    int params[100];
    Program *aux = (Program*) malloc(sizeof(Program));
    aux = instruction->exp.invoke->params;
    
    for (i=0; aux != NULL; i++) {
        params[i] = aux->cur_instruction->exp.int_value;
        aux = aux->next_instruction;
    }
    
    Function *function = (Function*) malloc(sizeof(Function));
    function = findAtom(createFnAtomLabel(instruction->exp.invoke->atom->exp.atom, i));
    
    Local *new = (Local*) malloc(sizeof(Local));
    Context *newContext = (Context*) malloc(sizeof(Context));

    if (function != NULL) {
        if(function->params != NULL) {
            aux = function->params;
            contextoAtual = (Context*) malloc(sizeof(Context));
            contextoAtual = context;
            while(aux != NULL) {
                addParameter(aux->cur_instruction->exp.atom, params[i-1]);
                Local *local = (Local*) malloc(sizeof(Local));
                local = findParameter(aux->cur_instruction->exp.atom, contextoAtual);
                aux = aux->next_instruction;
                i--;
            }
        }

        newContext->stack = (Local*) malloc(sizeof(Local));
        newContext->stack = contextoAtual->stack;
        STACK_PUSH(contextoAtual, newContext);
        run(function->code.subroutine, context);
        result = context->result;
        STACK_POP(contextoAtual, contextoAtual);
        context->result = result;
    } else {
        PRINT_COLOR(KRED);
        printf("Function cannot be called!\n");
        PRINT_COLOR(KNRM);
        return;
    }

    return;
}

void add_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO ADD\n\n");
    exec_instruction(instruction->exp.add->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.add->rhs, context);
    int rhs = context->result;
    context->result = lhs + rhs;
    return;
}

void sub_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO SUB\n\n");
    exec_instruction(instruction->exp.sub->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.sub->rhs, context);
    int rhs = context->result;
    context->result = (lhs) - (rhs);
    return;
}

void mul_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO MUL\n\n");
    exec_instruction(instruction->exp.mul->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.mul->rhs, context);
    int rhs = context->result;
    context->result = lhs * rhs;
    return;
}

void div_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO DIV\n\n");
    exec_instruction(instruction->exp.div->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.div->rhs, context);
    int rhs = context->result;
    context->result = lhs / rhs;
    return;
}

void and_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO AND\n\n");
    exec_instruction(instruction->exp.and->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.and->rhs, context);
    int rhs = context->result;
    context->result = lhs && rhs;
    return;
}

void or_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO OR\n\n");
    exec_instruction(instruction->exp.or->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.or->rhs, context);
    int rhs = context->result;
    context->result = lhs || rhs;
    return;
}

void not_exec ( Instruction *instruction, Context *context ) {
    Context *res;
    printf("EXECUTANDO NOT\n\n");
    res = (Context*) malloc(sizeof(Context));
    exec_instruction(instruction->exp.not->instruction, context);
    res = context;
    context->result = !(res->result);
    return;
}

void gt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO GT\n\n");
    exec_instruction(instruction->exp.gt->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.gt->rhs, context);
    int rhs = context->result;
    context->result = lhs > rhs;
    return;
}

void lt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO LT\n\n");
    exec_instruction(instruction->exp.lt->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.lt->rhs, context);
    int rhs = context->result;
    context->result = lhs < rhs;
    return;
}

void goeq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO GOEQ\n\n");
    exec_instruction(instruction->exp.goeq->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.goeq->rhs, context);
    int rhs = context->result;
    context->result = lhs >= rhs;
    return;
}

void loeq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO LOEQ\n\n");
    exec_instruction(instruction->exp.loeq->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.loeq->rhs, context);
    int rhs = context->result;
    context->result = lhs <= rhs;
    return;
}

void eq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO EQ\n\n");
    exec_instruction(instruction->exp.eq->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.eq->rhs, context);
    int rhs = context->result;
    context->result = lhs == rhs;
    return;
}

void neq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO NEQ\n\n");
    exec_instruction(instruction->exp.neq->lhs, context);
    int lhs = context->result;
    exec_instruction(instruction->exp.neq->rhs, context);
    int rhs = context->result;
    context->result = lhs != rhs;
    return;
}

void head_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO HEAD\n\n");
    return;
}

void tail_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO TAIL\n\n");
    return;
}

void cons_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO CONS\n\n");
    return;
}

void count_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO COUNT\n\n");
    Program *aux = (Program*) malloc(sizeof(Program));
    aux = instruction->exp.count->vector->exp.vector;
    int i;
    for (i=0; aux != NULL; i++) {
        aux = aux->cur_instruction->exp.vector->next_instruction;
    }
    context->result = i;
    return;
}

void map_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO MAP\n\n");
    return;
}

void filter_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO FILTER\n\n");
    return;
}

void ifstmt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO IF\n\n");
    Context *res;

    res = (Context*) malloc(sizeof(Context));
    exec_instruction(instruction->exp.ifstmt->cond, context);
    res = context;
    if (res->result) {
        exec_instruction(instruction->exp.ifstmt->ifStmt, context);
        res = context;
    } else {
        exec_instruction(instruction->exp.ifstmt->elseStmt, context);
        res = context;
    }
    context->result = res->result;
    return;
}

void write_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO WRITE\n\n");
    exec_instruction(instruction->exp.write->instruction, context);
    printf("=> %d\n\n", context->result);
    return;
}

void read_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO READ\n\n");
    return;
}

Function* findAtom(char* atom) {
    Function* s = (Function*) malloc(sizeof(Function));
    HASH_FIND_STR(symbolTable, atom, s);
    if(s != NULL) return s;
    return NULL;
}

Local* findParameter(char *atom, Context *context) {
    Local *local = (Local*) malloc(sizeof(Local));
    HASH_FIND_STR(contextoAtual->stack, atom, local);
    if (local != NULL) { return local; }
    return NULL;
}

void addParameter(char* atom, int value) {
    Local *local = (Local*) malloc(sizeof(Local));
    local->atom = (char*) strdup(atom);
    local->value = value;
    HASH_ADD_STR(contextoAtual->stack, atom, local);
}

void addAtom(char* atom, Program *code, Program *params) {
    char errorMessage[400];
    if(findAtom(atom) == NULL) {
        Function* s = (Function*) malloc(sizeof(Function));
        strcpy(s->atom, atom);
        s->id = symbolID++;
        s->code.subroutine = code;
        s->params = params;
        HASH_ADD_STR(symbolTable, atom, s);
        if(!hasSymbols) { hasSymbols = TRUE; }
    } else {
        snprintf(errorMessage, 400, "\nFunction already declared");
    }
}

char* createFnAtomLabel(char* s, int a) {
    char* str = (char*) malloc(sizeof(char)*60);
    snprintf(str, 60, "%s/%d", s, a);
    return str;
}

void run(Program *program, Context *context) {
    if(program != NULL) {
        exec_instruction(program->cur_instruction, context);
        run(program->next_instruction, context);
    }
}