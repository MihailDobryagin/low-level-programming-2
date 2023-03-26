%{
void yyerror (char *s);
int yylex();
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <stdbool.h>
#include "signatures.h"

struct View tree = {0};
size_t vtype;
struct Related_node rel_node = {0};
struct Related_node empty_rel_node = {0};
size_t size;
size_t stack_filter_size = 0;
struct Filter stack_filter[20];
struct Filter empty_filter;

void set_opcode(uint8_t opcode);
void append_native_logic(char* field, uint64_t val_param, enum Condition_code opcode);
struct Value get_val(uint64_t val_param);
void append_native_field(char* name, uint64_t val_param, bool with_value);
void append_related_node(char* tag_name);
void append_field_to_rel(char* field_name);
void print_value(struct Value value);
void print_condition(struct Filter filter);
void print_native_field(struct Native_field field);
void print_related_node(struct Related_node node);
void print_tree();
void set_cur_logic_operation(uint8_t op);
void append_filters_to_root();
void append_filters_to_child();
%}

%union {uint64_t num; char *string;}
%token QUERY INSERT DELETE UPDATE
%token <string> STRING
%token AND OR NOT
%token LT LE GT GE EQ
%token OPBRACE CLBRACE
%token OPCBRACE CLCBRACE
%token OPSQBRACE CLSQBRACE
%token COLON COMMA QUOTE
%token <num> FALSE TRUE INT_NUMBER
%type <num> logic_native_operation bool value logic_operation

%%

/*
query {
    Book (not: [id: {eq: 123}]) {
        title: "Under pit in the rye",
        color,
        language,
        Author (and: [name: {eq: "Mark"}, age: {ge: 5}]) {
            name,
            age
        }
    }
}
*/

syntax: graphQL {print_tree();};

graphQL: operation OPCBRACE body CLCBRACE;

operation: QUERY {set_opcode(0);}
        | DELETE {set_opcode(1);}
        | INSERT {set_opcode(2);}
        | UPDATE {set_opcode(3);};

body: STRING OPBRACE root_condition CLBRACE OPCBRACE tag CLCBRACE {memcpy(&tree.header.tag, $1, strlen($1));};

root_condition: | condition {append_filters_to_root();}
child_condition: | condition {append_filters_to_child();}

condition: logic_function | logic_native;

logic_function: NOT COLON OPSQBRACE condition CLSQBRACE {set_cur_logic_operation(0);}
                |
                logic_operation COLON OPSQBRACE condition_seq CLSQBRACE {set_cur_logic_operation($1);};

logic_operation: AND {$$ = 1;}| OR {$$ = 2;};

condition_seq: condition COMMA condition;

logic_native: STRING COLON OPCBRACE logic_native_operation COLON value CLCBRACE {append_native_logic($1, $6, $4);};

logic_native_operation: LT {$$ = 2;}|
                        LE {$$ = 3;}|
                        GT {$$ = 1;}|
                        GE {$$ = 4;}|
                        EQ {$$ = 0;};



tag: tag_rule COMMA tag | tag_rule;

tag_rule: simple_field | related_node;

simple_field:   STRING {append_native_field($1, 0, false);};
                |
                STRING COLON value {append_native_field($1, $3, true);};

related_node: STRING OPBRACE child_condition CLBRACE OPCBRACE simple_immutable_fields CLCBRACE {append_related_node($1);};

simple_immutable_fields: STRING COMMA simple_immutable_fields {append_field_to_rel($1);}
                        |
                        STRING {append_field_to_rel($1);}
                        |;


value : QUOTE STRING QUOTE {vtype = STRING_TYPE; $$ = $2;}
        |
        INT_NUMBER {vtype = INTEGER_TYPE; $$ = $1;}
        |
        bool {vtype = BOOLEAN_TYPE; $$ = $1;}
    ;

bool : TRUE {$$ = 1;}
       |
       FALSE {$$ = 0;}
       ;


%%                     /* C code */

int main (void) {
    return yyparse ();
}


void *test_malloc(size_t size_of){
    size += size_of;
    return malloc(size_of);
}

void print_ram(){
    printf("RAM USAGE: %zu bytes\n", size);
}

void append_filters_to_root(){
    if (tree.operation == CRUD_INSERT){
        yyerror("# warning: filters will be ignored via insert operation\n");
    }
    stack_filter_size=0;
    tree.header.filter = stack_filter[stack_filter_size];
    tree.header.filter_not_null = 1;
}

void append_filters_to_child(){
    //stack_filter_size=0;
    //tree.related_nodes[tree.related_nodes_count - 1].header.filter = stack_filter[stack_filter_size];
    //tree.related_nodes[tree.related_nodes_count - 1].header.filter_not_null = 1;
}

void set_cur_logic_operation(uint8_t op){

    enum Logic_op logic_op = op;
    struct Logic_func *function = test_malloc(sizeof(struct Logic_func));
    function->type = logic_op;
    struct Filter wrap_filter = {0};
    switch(logic_op){
        case OP_NOT: function->filters[0] = stack_filter[--stack_filter_size]; break;
        case OP_AND:
        case OP_OR: function->filters[0] = stack_filter[--stack_filter_size];
                    function->filters[1] = stack_filter[--stack_filter_size];
                    break;
    }
    wrap_filter.func = function;
    stack_filter[stack_filter_size] = wrap_filter;
    stack_filter_size++;
}

void append_native_logic(char* field, uint64_t val_param, enum Condition_code opcode){
    struct Value value = get_val(val_param);
    struct Native_filter *filter = malloc(sizeof(struct Native_filter));
    memcpy(filter->name, field, strlen(field));
    filter->name[strlen(field)] = '\0';
    filter->opcode = opcode;
    filter->value = value;
    struct Filter wrap_filter = {.is_native = 1, .filter = filter};
    stack_filter[stack_filter_size] = wrap_filter;
    stack_filter_size++;
}

struct Value get_val(uint64_t val_param){
    struct Value value = {.type = vtype};
    switch (value.type){
        case STRING_TYPE:
        memcpy(value.string, val_param, strlen((char*)val_param));
        value.string[strlen((char*)val_param)] = '\0';
        break;
        case INTEGER_TYPE:
        value.integer = val_param;
        break;
        case BOOLEAN_TYPE:
        value.boolean = val_param;
        break;
    }
    return value;
}

void append_native_field(char* name, uint64_t val_param, bool with_value){
    struct Native_field field;
    memcpy(field.name, name, strlen(name));
    field.name[strlen(name)] = '\0';
    if (with_value){
        if (tree.operation == CRUD_QUERY || tree.operation == CRUD_REMOVE){
            yyerror("# warning: body values will be ignored via query operation\n");
        }
        struct Value value = get_val(val_param);
        field.value = value;
    }
    tree.native_fields[tree.native_fields_count++] = field;

}

void append_related_node(char* tag_name){
    if (stack_filter_size > 0) {
        rel_node.header.filter = stack_filter[stack_filter_size-1];
        rel_node.header.filter_not_null = 1;
        stack_filter_size--;
    }
    memcpy(rel_node.header.tag, tag_name, strlen(tag_name));
    rel_node.header.tag[strlen(tag_name)] = '\0';

    tree.related_nodes[tree.related_nodes_count++] = rel_node;
    rel_node = empty_rel_node;

}

void append_field_to_rel(char* field_name){
    if (tree.operation != CRUD_QUERY){
        yyerror("# warning: related node values will be ignored via non-query operation\n");
    }
    rel_node.field_names[rel_node.native_fields_count++] = field_name;
}

void set_opcode(uint8_t opcode){
    tree.operation = opcode;
    struct Header h = {0};
    tree.header = h;
}

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

void print_native_field(struct Native_field field){
    printf("%s", field.name);
    if (tree.operation == CRUD_UPDATE || tree.operation == CRUD_INSERT) {
        printf(": ");
        print_value(field.value);
    }
    printf("\n");
}

void print_related_node(struct Related_node node){
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

void print_tree(){
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
        print_native_field(tree.native_fields[i]);
    printf("\n[RELATED NODES]: \n");
    for (size_t i = 0; i < tree.related_nodes_count; i++){
        printf("\n\t[RELATED NODE %zu]: \n", i);
        print_related_node(tree.related_nodes[i]);
    }



}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}
