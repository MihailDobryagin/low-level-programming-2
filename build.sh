clear
yacc -d graphQL.y
lex lex.l
gcc -w lex.yy.c y.tab.c -o out
./out < query.gql
rm lex.yy.c y.tab.c y.tab.h out