#include "interpreter.h"

Context* exec_instruction ( Instruction *instruction, Context *context) {
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
            return NULL;
    }
}

Context* nil_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO NIL\n\n");
    return NULL;
}

Context* int_value_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO INT\n\n");
    return NULL;
}

Context* int_vector_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO VECTOR\n\n");
    return NULL;
}

Context* atom_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO ATOM\n\n");
    return NULL;
}

Context* invoke_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO INVOKE\n\n");
    return NULL;
}

Context* add_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO ADD\n\n");
    return NULL;
}

Context* sub_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO SUB\n\n");
    return NULL;
}

Context* mul_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO MUL\n\n");
    return NULL;
}

Context* div_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO DIV\n\n");
    return NULL;
}

Context* and_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO AND\n\n");
    return NULL;
}

Context* or_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO OR\n\n");
    return NULL;
}

Context* not_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO NOT\n\n");
    return NULL;
}

Context* gt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO GT\n\n");
    return NULL;
}

Context* lt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO LT\n\n");
    return NULL;
}

Context* goeq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO GOEQ\n\n");
    return NULL;
}

Context* loeq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO LOEQ\n\n");
    return NULL;
}

Context* eq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO EQ\n\n");
    return NULL;
}

Context* neq_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO NEQ\n\n");
    return NULL;
}

Context* head_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO HEAD\n\n");
    return NULL;
}

Context* tail_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO TAIL\n\n");
    return NULL;
}

Context* cons_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO CONS\n\n");
    return NULL;
}

Context* count_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO COUNT\n\n");
    return NULL;
}

Context* map_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO MAP\n\n");
    return NULL;
}

Context* filter_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO FILTER\n\n");
    return NULL;
}

Context* ifstmt_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO IF\n\n");
    context = exec_instruction(instruction->exp.ifstmt->ifStmt, context);
    return NULL;
}

Context* write_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO WRITE\n\n");
    return NULL;
}

Context* read_exec ( Instruction *instruction, Context *context ) {
    printf("EXECUTANDO READ\n\n");
    return NULL;
}


int i = 1;

void run(Program *program, Context *context) {
    if(program != NULL) {
        context = exec_instruction(program->cur_instruction, context);
        run(program->next_instruction, context);
    }
}