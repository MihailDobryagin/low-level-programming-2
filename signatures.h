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
    OP_AND = 0,
    OP_OR,
    OP_NOT
};

enum Type {
    STRING_TYPE = 0,
    INTEGER_TYPE,
    BOOLEAN_TYPE
};

struct Value {
    enum Type type;
    union {
        char string[MAX_NAME_SIZE];
        int64_t integer;
        int64_t boolean;
    };
};

struct Filter;

struct Native_filter {
    char name[MAX_NAME_SIZE];
    enum Condition_code opcode;
    struct Value value;
}

struct Logic_func {
    enum Logic_op type;
    size_t filters_count;
    struct Filter filters[MAX_ARRAY_SIZE];
}

struct Filter {
    uint8_t is_native;
    union {
        struct Logic_func *func;
        struct Native_filter *filter;
    };
};

struct View;

struct Native_field {
    char name[MAX_NAME_SIZE];
    struct Value value;
}

struct Related_node {
    struct Header header;
    size_t native_fields_count;
    struct Native_field native_fields[MAX_ARRAY_SIZE];
}

struct Header {
    char tag[MAX_NAME_SIZE];
    struct Filter filter;
}

struct View {
    enum Crud_operation operation;
    struct Header header;
    size_t native_fields_count;
    struct Native_field native_fields[MAX_ARRAY_SIZE];
    size_t related_fields_count;
    struct Related_node related_fields[MAX_ARRAY_SIZE];
};





