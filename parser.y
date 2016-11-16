%{
#include <stdio.h>
#include <string.h>
#include "tree.h"
#include "symbol.h"


int yylex();
extern int yylineno;
void yyerror(const char *);
void yyerror2(const char *, const char *);

%}


%union {
    struct ast *a;
}

%token <a> INT FLOAT ID
%token <a> SEMI COMMA ASSIGNOP RELOP
%token <a> PLUS MINUS STAR DIV AND OR DOT NOT
%token <a> TYPE LP RP LB RB LC RC
%token <a> STRUCT RETURN IF ELSE WHILE
%token SPACE

%type <a> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier
%type <a> OptTag Tag VarDec FunDec VarList ParamDec CompSt StmtList
%type <a> Stmt DefList Def DecList Dec Exp Args

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right UMINUS NOT
%left LP RP LB RB COMMA DOT

%%
Program:ExtDefList { 
    $$ = newast1(makeTextVal("Program"), $1);
    tracetree($$, 0);
    printf("\n");
    initSymTable();
    semantic($$);
    freetree($$);
}
    ;
ExtDefList: { $$ = newast(0, makeTextVal("ExtDefList")); }
    |ExtDef ExtDefList { $$ = newast2(makeTextVal("ExtDefList"), $1, $2); }
    ;
ExtDef: Specifier ExtDecList SEMI { $$ = newast2(makeTextVal("ExtDef"), $1, $2); }
    |Specifier SEMI { $$ = newast1(makeTextVal("ExtDef"), $1); }
    |Specifier FunDec CompSt { $$ = newast3(makeTextVal("ExtDef"), $1, $2, $3); }
    |error SEMI { yyerrok; }
    ;
ExtDecList: VarDec { $$ = newast1(makeTextVal("ExtDecList"), $1); }
    |VarDec COMMA ExtDecList { $$ = newast2(makeTextVal("ExtDecList"), $1, $3); }
    ;
Specifier: TYPE { $$ = newast1(makeTextVal("Specifier Type"), $1); }
    |StructSpecifier { $$ = newast1(makeTextVal("Specifier Struct"), $1); }
    ;
StructSpecifier: STRUCT OptTag LC DefList RC { $$ = newast2(makeTextVal("StructSpecifier"), $2, $4); }
    |STRUCT Tag { $$ = newast1(makeTextVal("StructSpecifier"), $2); }
    ;
OptTag: { $$ = newast(0, makeTextVal("OptTag")); }
    |ID { $$ = newast1(makeTextVal("OptTag"), $1); }
    ;
Tag: ID { $$ = newast1(makeTextVal("Tag"), $1); }
    ;
VarDec: ID { $$ = newast1(makeTextVal("VarDec"), $1); }
    |VarDec LB INT RB { $$ = newast2(makeTextVal("VarDec"), $1, $3); }
    ;
FunDec: ID LP VarList RP { $$ = newast2(makeTextVal("FunDec"), $1, $3); }
    |ID LP RP { $$ = newast1(makeTextVal("FunDec"), $1); }
    ;
VarList: ParamDec COMMA VarList { $$ = newast2(makeTextVal("VarList"), $1, $3); }
    |ParamDec { $$ = newast1(makeTextVal("VarList"), $1); }
    ;
ParamDec: Specifier VarDec { $$ = newast2(makeTextVal("ParamDec"), $1, $2); }
    ;
CompSt: LC DefList StmtList RC { $$ = newast2(makeTextVal("CompSt"), $2, $3); }
    |error RC {yyerrok;}
    ;
StmtList: { $$ = newast(0, makeTextVal("StmtList")); }
    |Stmt StmtList { $$ = newast2(makeTextVal("StmtList"), $1, $2); }
    ;
Stmt: Exp SEMI { $$ = newast1(makeTextVal("Stmt Exp"), $1); }
    |CompSt { $$ = newast1(makeTextVal("Stmt Comp"), $1); }
    |RETURN Exp SEMI { $$ = newast1(makeTextVal("Stmt Return"), $2); }
    |IF LP Exp RP Stmt %prec LOWER_THAN_ELSE { $$ = newast2(makeTextVal("Stmt If"), $3, $5); }
    |IF LP Exp RP Stmt ELSE Stmt { $$ = newast3(makeTextVal("Stmt IfElse"), $3, $5, $7); }
    |WHILE LP Exp RP Stmt { $$ = newast2(makeTextVal("Stmt While"), $3, $5); }
    ;
DefList: { $$ = newast(0, makeTextVal("DefList")); }
    |Def DefList { $$ = newast2(makeTextVal("DefList"), $1, $2); }
    ;
Def: Specifier DecList SEMI { $$ = newast2(makeTextVal("Def"), $1, $2); }
    ;
DecList: Dec { $$ = newast1(makeTextVal("DecList"), $1); }
    |Dec COMMA DecList { $$ = newast2(makeTextVal("DecList"), $1, $3); }
    ;
Dec: VarDec { $$ = newast1(makeTextVal("Dec"), $1);}
    |VarDec ASSIGNOP Exp { $$ = newast2(makeTextVal("Dec"), $1, $3); }
    ;
Exp: Exp ASSIGNOP Exp { $$ = newast2(makeTextVal("Exp Assign"), $1, $3); }
    |Exp AND Exp { $$ = newast2(makeTextVal("Exp And"), $1, $3); }
    |Exp OR Exp { $$ = newast2(makeTextVal("Exp Or"), $1, $3); }
    |Exp RELOP Exp { $$ = newast3(makeTextVal("Exp Relop"), $1, $2, $3); }
    |Exp PLUS Exp { $$ = newast2(makeTextVal("Exp Plus"), $1, $3); }
    |Exp MINUS Exp { $$ = newast2(makeTextVal("Exp Minus"), $1, $3); }
    |Exp STAR Exp { $$ = newast2(makeTextVal("Exp Star"), $1, $3); }
    |Exp DIV Exp { $$ = newast2(makeTextVal("Exp Div"), $1, $3); }
    |LP Exp RP { $$ = newast1(makeTextVal("Exp"), $2); }
    |MINUS Exp %prec UMINUS { $$ = newast1(makeTextVal("Exp UMinus"), $2); }
    |NOT Exp { $$ = newast1(makeTextVal("Exp Not"), $2); }
    |ID LP Args RP { $$ = newast2(makeTextVal("Exp Call"), $1, $3); }
    |ID LP RP { $$ = newast1(makeTextVal("Exp Call"), $1); }
    |Exp LB Exp RB { $$ = newast2(makeTextVal("Exp Array"), $1, $2); }
    |Exp DOT ID { $$ = newast2(makeTextVal("Exp Dot"), $1, $3); }
    |ID { $$ = newast1(makeTextVal("Exp ID"), $1); }
    |INT { $$ = newast1(makeTextVal("Exp Int"), $1); }
    |FLOAT { $$ = newast1(makeTextVal("Exp Float"), $1); }
    |error RP {yyerrok;}
    ;
Args: Exp COMMA Args { $$ = newast2(makeTextVal("Args"), $1, $3); }
    |Exp { $$ = newast1(makeTextVal("Args"), $1); }
    ;
;
%%

int main() {
    yyparse();
}

void yyerror(const char *msg) {
    fprintf(stderr,"Error Type B at line %d: %s\n", yylineno, msg);
}

void yyerror2(const char *type, const char *msg) {
    fprintf(stderr,"Error Type %s at line %d: %s\n", type, yylineno, msg);
}


