#include <inttypes.h>

#define MAX_NAME_SIZE 20
#define MAX_ARRAY_SIZE 20

enum Crud_operation {
    CRUD_QUERY = 0,
    CRUD_REMOVE,
    CRUD_INSERT,
    CRUD_UPDATE
};

enum Condition_code {
    OP_EQUAL = 0,
    OP_GREATER,
    OP_LESS,
    OP_NOT_GREATER,
    OP_NOT_LESS
};

enum Logic_op {
    OP_NOT = 0,
    OP_AND,
    OP_OR

};

enum Type {
    STRING_TYPE = 0,
    INTEGER_TYPE,
    BOOLEAN_TYPE
};

struct Header;
struct View;
struct Filter;

struct Value {
    enum Type type;
    union {
        char string[MAX_NAME_SIZE];
        int32_t integer;
        int8_t boolean;
    };
};


struct Native_filter {
    char name[MAX_NAME_SIZE];
    enum Condition_code opcode;
    struct Value value;
};
struct Filter {

    uint8_t is_native;
    union {
        struct Logic_func *func;
        struct Native_filter *filter;
    };
};
struct Logic_func {
    enum Logic_op type;
    struct Filter filters[2];
};




struct Native_field {
    char name[MAX_NAME_SIZE];
    struct Value value;
};



struct Header {
    uint8_t filter_not_null;
    char tag[MAX_NAME_SIZE];
    struct Filter filter;
};

struct Related_node {
    size_t native_fields_count;
    char* field_names[MAX_ARRAY_SIZE];
    struct Header header;
};

struct View {
    enum Crud_operation operation;
    struct Header header;
    size_t native_fields_count;
    struct Native_field native_fields[MAX_ARRAY_SIZE];
    size_t related_nodes_count;
    struct Related_node related_nodes[MAX_ARRAY_SIZE];
};





