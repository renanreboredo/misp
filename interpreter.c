#include "interpreter.h"

Context* exec_instruction ( Instruction *instruction, Context *context) {
    switch (instruction->type)
    {
        case NIL_EXP:
            return nil_exec(instruction, context);
            break;
        
        case INT_EXP:
            return int_value_exec(instruction, context);
            break;

        case VECTOR_EXP:
            return int_vector_exec(instruction, context);
            break;
        
        case ATOM_EXP:
            return atom_exec(instruction, context);
            break;
        
        case INVOKE_EXP:
            return invoke_exec(instruction, context);
            break;
        
        case ADD_EXP:
            return add_exec(instruction, context);
            break;
        
        case SUB_EXP:
            return sub_exec(instruction, context);
            break;
        
        case MUL_EXP:
            return mul_exec(instruction, context);
            break;
        
        case DIV_EXP:
            return div_exec(instruction, context);
            break;
        
        case AND_EXP:
            return and_exec(instruction, context);
            break;
        
        case OR_EXP:
            return or_exec(instruction, context);
            break;
        
        case NOT_EXP:
            return not_exec(instruction, context);
            break;
        
        case GT_EXP:
            return gt_exec(instruction, context);
            break;
        
        case LT_EXP:
            return lt_exec(instruction, context);
            break;
        
        case GOEQ_EXP:
            return goeq_exec(instruction, context);
            break;
        
        case LOEQ_EXP:
            return loeq_exec(instruction, context);
            break;
        
        case EQ_EXP:
            return eq_exec(instruction, context);
            break;
        
        case NEQ_EXP:
            return neq_exec(instruction, context);
            break;
        
        case HEAD_EXP:
            return head_exec(instruction, context);
            break;
        
        case TAIL_EXP:
            return tail_exec(instruction, context);
            break;
        
        case CONS_EXP:
            return cons_exec(instruction, context);
            break;
        
        case COUNT_EXP:
            return count_exec(instruction, context);
            break;
        
        case MAP_EXP:
            return map_exec(instruction, context);
            break;
        
        case FILTER_EXP:
            return filter_exec(instruction, context);
            break;

        case IF_EXP:
            return ifstmt_exec(instruction, context);
            break;
        
        case WRITE_EXP:
            return write_exec(instruction, context);
            break;
        
        case READ_EXP:
            return read_exec(instruction, context);
            break;  
        
        default:
            break;
    }
}

void run(Program *program, Context *context) {
    if(program->cur_instruction != NULL) {
        context = exec_instruction(program->cur_instruction, context);
        run(program->next_instruction, context);
    }
}