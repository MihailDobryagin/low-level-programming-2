#include "printer.h"

void print_value(struct Value value) {
    switch (value.type) {
        case STRING_TYPE: printf("%s ", value.string); break;
        case INTEGER_TYPE: printf("%ld ", value.integer); break;
        case BOOLEAN_TYPE: if (value.boolean) printf("True "); else printf("False "); break;
    }
}

void print_condition(struct Filter filter){
    if (filter.is_native) {
        printf("%s ", filter.filter->name);
        switch (filter.filter->opcode){
            case    OP_EQUAL:   printf("== "); break;
            case    OP_GREATER: printf("> "); break;
            case    OP_LESS:    printf("< "); break;
            case    OP_NOT_GREATER: printf("<= "); break;
            case    OP_NOT_LESS:printf(">= "); break;
        }
        print_value(filter.filter->value);
    } else {

        switch (filter.func->type){
            case    OP_AND: printf("and [ "); print_condition(filter.func->filters[1]); printf(", "); break;
            case    OP_OR: printf("or [ "); print_condition(filter.func->filters[1]); printf(", "); break;
            case    OP_NOT: printf("not [ "); break;
        }
        print_condition(filter.func->filters[0]);
        printf("] ");
    }

}

void print_native_field(struct View tree, struct Native_field field){
    printf("%s", field.name);
    if (tree.operation == CRUD_UPDATE || tree.operation == CRUD_INSERT) {
        printf(": ");
        print_value(field.value);
    }
    printf("\n");
}

void print_related_node(struct View tree, struct Related_node node){
    printf("\t|TAG|: %s\n", node.header.tag);
    if (node.header.filter_not_null) {
        printf("\t|CONDITIONS|: \n\t");
        print_condition(node.header.filter);
    }
    if (tree.operation == CRUD_UPDATE || tree.operation == CRUD_INSERT){
        printf("\n\t|REL NATIVE FIELDS|: \n");
        for (size_t i = 0; i < node.native_fields_count; i++)
            printf("\t%s,\n", node.field_names[i]);
    }
    printf("\n");
}

void print_tree(struct View tree){
    printf("[COMMAND]: ");
    switch (tree.operation){
        case CRUD_QUERY: printf("query\n\n"); break;
        case CRUD_REMOVE: printf("remove\n\n"); break;
        case CRUD_INSERT: printf("insert\n\n"); break;
        case CRUD_UPDATE: printf("update\n\n"); break;
    }
    printf("[TAG]: %s\n\n", tree.header.tag);

    if (tree.header.filter_not_null){
        printf("[CONDITIONS]: \n");
        print_condition(tree.header.filter);
        printf("\n\n");
    }

    printf("[NATIVE FIELDS]: \n");
    for (size_t i = 0; i < tree.native_fields_count; i++)
        print_native_field(tree, tree.native_fields[i]);
    printf("\n[RELATED NODES]: \n");
    for (size_t i = 0; i < tree.related_nodes_count; i++){
        printf("\n\t[RELATED NODE %zu]: \n", i);
        print_related_node(tree, tree.related_nodes[i]);
    }



}