/* The CHAPEL Parser */

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexyacc.h"
#include "chplalloc.h"

%}

%start program

%union  {
  bool boolval;
  char* pch;

  getsOpType got;
  varType vt;
  consType ct;
  paramType pt;

  Expr* pexpr;
  AList<Expr>* exprlist;
  ForallExpr* pfaexpr;
  Stmt* stmt;
  AList<Stmt>* stmtlist;
  DefStmt* defstmt;
  DefExpr* defexpr;
  AList<DefExpr>* defexprls;
  ForLoopStmt* forstmt;
  BlockStmt* blkstmt;
  Type* pdt;
  TupleType* tupledt;
  UnresolvedType* unresolveddt;
  EnumSymbol* enumsym;
  AList<EnumSymbol>* enumsymlist;
  Symbol* psym;
  AList<Symbol>* symlist;
  AList<ParamSymbol>* paramlist;
  VarSymbol* pvsym;
  TypeSymbol* ptsym;
  FnSymbol* fnsym;
  ModuleSymbol* modsym;
  Pragma* pragma;
  AList<Pragma>* pragmas;
}

%token TBREAK
%token TCALL
%token TCLASS
%token TCONFIG
%token TCONST
%token TCONSTRUCTOR
%token TPARAMETER
%token TCONTINUE
%token TDO
%token TDOMAIN
%token TENUM
%token TFOR
%token TFORALL
%token TFUNCTION
%token TGOTO
%token TIF
%token TIN
%token TINDEX
%token TINOUT
%token TLABEL
%token TLET
%token TLIKE
%token TMODULE
%token TNIL
%token TOF
%token TOUT
%token TPRAGMA
%token TRECORD
%token TREF
%token TRETURN
%token TSEQ
%token TSTATIC
%token TTHEN
%token TTYPE
%token TUNION
%token TUSE
%token TVAL
%token TVAR
%token TWHERE
%token TWHILE
%token TWITH

%token TIDENT QUERY_IDENT
%token INTLITERAL FLOATLITERAL COMPLEXLITERAL
%token <pch> STRINGLITERAL

%token TASSIGN;
%token TASSIGNPLUS;
%token TASSIGNMINUS;
%token TASSIGNMULTIPLY;
%token TASSIGNDIVIDE;
%token TASSIGNBAND;
%token TASSIGNBOR;
%token TASSIGNBXOR;

%token TSEMI;
%token TCOMMA;
%token TDOT;
%token TLP;
%token TRP;
%token TSEQBEGIN;
%token TSEQEND;
%token TLSBR;
%token TRSBR;
%token TLCBR;
%token TRCBR;
%token TCOLON
%token TNOTCOLON


%token TQUESTION;

%type <ct> varconst
 
%type <got> assignOp
%type <vt> vardecltag
%type <pt> formaltag

%type <boolval> fortype fnretref isconstructor
%type <pdt> type domainType indexType arrayType tupleType seqType
%type <tupledt> tupleTypes
%type <unresolveddt> unresolvedType
%type <pdt> vardecltype typevardecltype fnrettype
%type <pch> identifier query_identifier fname opt_identifier
%type <psym> ident_symbol
%type <symlist> ident_symbol_ls indexes indexlist
%type <paramlist> formal formals
%type <enumsym> enum_item
%type <enumsymlist> enum_list
%type <pexpr> lvalue declarable_expr atom expr expr_list_item literal range seq_expr where whereexpr
%type <exprlist> exprlist nonemptyExprlist
%type <pexpr> reduction optional_init_expr assignExpr conditional_expr
%type <pfaexpr> forallExpr
%type <stmt> statement call_stmt noop_stmt decl typevardecl
%type <stmtlist> decls statements modulebody program
%type <defexprls> vardecl_inner vardecl_inner_ls
%type <defstmt> vardecl
%type <stmt> assignment conditional retStmt loop forloop whileloop enumdecl
%type <pdt> structtype
%type <stmt> typealias typedecl fndecl structdecl moduledecl
%type <stmt> function_body_single_stmt 
%type <blkstmt> function_body_stmt block_stmt
%type <pragma> pragma
%type <pragmas> pragmas


/* These are declared in increasing order of precedence. */


%left TNOELSE
%left TELSE

%left TCOMMA

%left TCOLON
%left TNOTCOLON

%left TRSBR
%left TIN
%left TBY
%left TDOTDOT
%left TSEQCAT
%left TOR
%left TAND
%right TNOT
%left TEQUAL TNOTEQUAL
%left TLESSEQUAL TGREATEREQUAL TLESS TGREATER
%left TBOR
%left TBXOR
%left TBAND
%left TPLUS TMINUS
%left TSTAR TDIVIDE TMOD
%right TUPLUS TUMINUS TREDUCE TBNOT
%right TEXP

%left TLP
%left TDOT

%% 


program: modulebody
    { yystmtlist = $$; }
;


modulebody: 
  statements
;

vardecltag:
  /* nothing */
    { $$ = VAR_NORMAL; }
| TCONFIG
    { $$ = VAR_CONFIG; }
| TSTATIC
    { $$ = VAR_STATE; }
;


varconst:
  TVAR
    { $$ = VAR_VAR; }
| TCONST
    { $$ = VAR_CONST; }
| TPARAMETER
    { $$ = VAR_PARAM; }
;
        
ident_symbol:
 pragmas identifier
    { 
      $$ = new Symbol(SYMBOL, $2);
      $$->pragmas = $1;
    } 
;

ident_symbol_ls:
  ident_symbol
    { $$ = new AList<Symbol>($1); }
| ident_symbol_ls ident_symbol
    { $1->insertAtTail($2); }
;


vardecltype:
  /* nothing */
    { $$ = dtUnknown; }
| TCOLON type
    { $$ = $2; }
| TLIKE expr
    { $$ = new LikeType($2); }
;


optional_init_expr:
  /* nothing */
    { $$ = NULL; }
| TASSIGN expr
    { $$ = $2; }
;


vardecl_inner:
  ident_symbol_ls vardecltype optional_init_expr
    { $$ = Symboltable::defineVarDef1($1, $2, $3); }
;


vardecl_inner_ls:
  vardecl_inner
| vardecl_inner_ls TCOMMA vardecl_inner
    { $1->add($3); }
;


vardecl:
  vardecltag varconst vardecl_inner_ls TSEMI
    {
      Symboltable::defineVarDef2($3, $1, $2);
      $$ = new DefStmt($3);
    }
;

typedecl:
  typealias
| typevardecl
| enumdecl
| structdecl
;


typealias:
  TTYPE pragmas identifier TCOLON type optional_init_expr TSEMI
    {
      UserType* newtype = new UserType($5, $6);
      TypeSymbol* typeSym = new TypeSymbol($3, newtype);
      typeSym->pragmas = $2;
      newtype->addSymbol(typeSym);
      DefExpr* def_expr = new DefExpr(typeSym);
      $$ = new DefStmt(def_expr);
    }
;


typevardecl:
  TTYPE pragmas identifier TSEMI
    {
      VariableType* new_type = new VariableType(getMetaType(0));
      TypeSymbol* new_symbol = new TypeSymbol($3, new_type);
      new_symbol->pragmas = $2;
      new_type->addSymbol(new_symbol);
      DefExpr* def_expr = new DefExpr(new_symbol);
      $$ = new DefStmt(def_expr);
    }
;


enumdecl:
  TENUM pragmas identifier TLCBR enum_list TRCBR TSEMI
    {
      EnumSymbol::setValues($5);
      EnumType* pdt = new EnumType($5);
      TypeSymbol* pst = new TypeSymbol($3, pdt);
      pst->pragmas = $2;
      pdt->addSymbol(pst);
      DefExpr* def_expr = new DefExpr(pst);
      Symbol::setDefPoints($5, def_expr); /* SJD: Should enums have more DefExprs? */
      $$ = new DefStmt(def_expr);
    }
;


structtype:
  TCLASS
    { $$ = new ClassType(); }
| TRECORD
    { $$ = new RecordType(); }
| TUNION
    { $$ = new UnionType(); }
;


structdecl:
  structtype pragmas identifier TLCBR
    {
      $<ptsym>$ = Symboltable::startStructDef($1, $3);
      $<ptsym>$->pragmas = $2;
    }
                                      decls TRCBR
    {
      $$ = new DefStmt(Symboltable::finishStructDef($<ptsym>5, $6));
    }
;


enum_item:
  identifier
    {
      $$ = new EnumSymbol($1, NULL);
    }
| identifier TASSIGN expr
    {
      $$ = new EnumSymbol($1, $3);
    }
;


enum_list:
  enum_item
    {
      $$ = new AList<EnumSymbol>($1);
    }
| enum_list TCOMMA enum_item
    {
      $1->insertAtTail($3);
      $$ = $1;
    }
;


formaltag:
  /* nothing */
    { $$ = PARAM_BLANK; }
| TIN
    { $$ = PARAM_IN; }
| TINOUT
    { $$ = PARAM_INOUT; }
| TOUT
    { $$ = PARAM_OUT; }
| TCONST
    { $$ = PARAM_CONST; }
| TPARAMETER
    { $$ = PARAM_PARAMETER; }
;


typevardecltype:
  /* nothing */
    { $$ = NULL; }
| TCOLON type
    { $$ = $2; }
;


formal:
  formaltag ident_symbol_ls vardecltype optional_init_expr
    {
      $$ = Symboltable::defineParams($1, $2, $3, $4);
    }
| TTYPE ident_symbol typevardecltype
    {
      AList<ParamSymbol> *psl = Symboltable::defineParams(PARAM_BLANK, new AList<Symbol>($2), getMetaType($3), NULL);
      ParamSymbol* ps = psl->only();
      if (ps == NULL) {
        INT_FATAL("problem in parsing type variables");
      }
      char *name = glomstrings(2, "__type_variable_", ps->name);
      VariableType* new_type = new VariableType(getMetaType($3));
      TypeSymbol* new_type_symbol = new TypeSymbol(name, new_type);
      new_type->addSymbol(new_type_symbol);
      ps->typeVariable = new_type_symbol;
      ps->isGeneric = 1;
      $$ = psl;
    }
;


formals:
  /* empty */
    { $$ = new AList<ParamSymbol>(); }
| formal
| formals TCOMMA formal
    { $1->add($3); }
;


fnrettype:
  /* empty */
    { $$ = dtUnknown; }
| TCOLON type
    { $$ = $2; }
;


fnretref:
  /* empty */
    { $$ = false; }
| TVAR
    { $$ = true; }
;


fname:
  identifier
| TASSIGN identifier
  { $$ = glomstrings(2, "=", $2); } 
| TASSIGN 
  { $$ = "="; } 
| TASSIGNPLUS
  { $$ = "+="; } 
| TASSIGNMINUS
  { $$ = "-="; } 
| TASSIGNMULTIPLY
  { $$ = "*="; } 
| TASSIGNDIVIDE
  { $$ = "/="; } 
| TASSIGNBAND
  { $$ = "&="; } 
| TASSIGNBOR
  { $$ = "|="; } 
| TASSIGNBXOR
  { $$ = "^="; } 
| TBAND
  { $$ = "&"; } 
| TBOR
  { $$ = "|"; } 
| TBXOR
  { $$ = "^"; } 
| TBNOT
  { $$ = "~"; } 
| TEQUAL
  { $$ = "=="; } 
| TNOTEQUAL
  { $$ = "!="; } 
| TLESSEQUAL
  { $$ = "<="; } 
| TGREATEREQUAL
  { $$ = ">="; } 
| TLESS
  { $$ = "<"; } 
| TGREATER
  { $$ = ">"; } 
| TPLUS 
  { $$ = "+"; } 
| TMINUS
  { $$ = "-"; } 
| TSTAR
  { $$ = "*"; } 
| TDIVIDE
  { $$ = "/"; } 
| TMOD
  { $$ = "mod"; } 
| TEXP
  { $$ = "**"; } 
| TAND
  { $$ = "and"; } 
| TOR
  { $$ = "or"; } 
| TBY
  { $$ = "by"; } 
| TSEQCAT
  { $$ = "#"; } 
  ;

isconstructor:
  TFUNCTION
    { $$ = false; }
| TCONSTRUCTOR
    { $$ = true; }
;

where:
  /* empty */
    { $$ = NULL; }
| TWHERE whereexpr
    { $$ = $2; }
;

whereexpr: 
  identifier
    { $$ = new Variable(new UnresolvedSymbol($1)); }
| TTYPE identifier
    { $$ = new DefExpr(new TypeSymbol($2, new VariableType)); }
| TNOT whereexpr
    { $$ = new UnOp(UNOP_LOGNOT, $2); }
| TBNOT whereexpr
    { $$ = new UnOp(UNOP_BITNOT, $2); }
| whereexpr TPLUS whereexpr
    { $$ = Expr::newPlusMinus(BINOP_PLUS, $1, $3); }
| whereexpr TMINUS whereexpr
    { $$ = Expr::newPlusMinus(BINOP_MINUS, $1, $3); }
| whereexpr TSTAR whereexpr
    { $$ = new BinOp(BINOP_MULT, $1, $3); }
| whereexpr TDIVIDE whereexpr
    { $$ = new BinOp(BINOP_DIV, $1, $3); }
| whereexpr TMOD whereexpr
    { $$ = new BinOp(BINOP_MOD, $1, $3); }
| whereexpr TEQUAL whereexpr
    { $$ = new BinOp(BINOP_EQUAL, $1, $3); }
| whereexpr TNOTEQUAL whereexpr
    { $$ = new BinOp(BINOP_NEQUAL, $1, $3); }
| whereexpr TLESSEQUAL whereexpr
    { $$ = new BinOp(BINOP_LEQUAL, $1, $3); }
| whereexpr TGREATEREQUAL whereexpr
    { $$ = new BinOp(BINOP_GEQUAL, $1, $3); }
| whereexpr TLESS whereexpr
    { $$ = new BinOp(BINOP_LTHAN, $1, $3); }
| whereexpr TGREATER whereexpr
    { $$ = new BinOp(BINOP_GTHAN, $1, $3); }
| whereexpr TBAND whereexpr
    { $$ = new BinOp(BINOP_BITAND, $1, $3); }
| whereexpr TBOR whereexpr
    { $$ = new BinOp(BINOP_BITOR, $1, $3); }
| whereexpr TBXOR whereexpr
    { $$ = new BinOp(BINOP_BITXOR, $1, $3); }
| whereexpr TAND whereexpr
    { $$ = new BinOp(BINOP_LOGAND, $1, $3); }
| whereexpr TCOMMA whereexpr
    { $$ = new BinOp(BINOP_LOGAND, $1, $3); }
| whereexpr TOR whereexpr
    { $$ = new BinOp(BINOP_LOGOR, $1, $3); }
| whereexpr TEXP whereexpr
    { $$ = new BinOp(BINOP_EXP, $1, $3); }
| whereexpr TCOLON whereexpr
    { $$ = new BinOp(BINOP_SUBTYPE, $1, $3); }
| whereexpr TNOTCOLON whereexpr
    { $$ = new BinOp(BINOP_NOTSUBTYPE, $1, $3); }
| whereexpr TDOT identifier
    { $$ = new MemberAccess($1, new UnresolvedSymbol($3)); }
| TLP whereexpr TRP
    { $$ = $2; }
| structtype pragmas opt_identifier TLCBR decls TRCBR
    { $$ = NULL; }
| whereexpr TLP exprlist TRP   
    { $$ = new ParenOpExpr($1, $3); }
;


fndecl:
  isconstructor fname
    {
      $<fnsym>$ = Symboltable::startFnDef(new FnSymbol($2));
      $<fnsym>$->isConstructor = $1;
    }
                       TLP formals TRP fnretref fnrettype where
    {
      Symboltable::continueFnDef($<fnsym>3, $5, $8, $7);
    }
                                                 function_body_stmt
    {
      $$ = new DefStmt(new DefExpr(Symboltable::finishFnDef($<fnsym>3, $11)));
    }
|
  isconstructor identifier TDOT fname
    {
      $<fnsym>$ =
        Symboltable::startFnDef(new FnSymbol($4, new UnresolvedSymbol($2)));
      $<fnsym>$->isConstructor = $1;
    }
                                  TLP formals TRP fnretref fnrettype where
    {
      Symboltable::continueFnDef($<fnsym>5, $7, $10, $9);
    }
                                                            function_body_stmt
    {
      $$ = new DefStmt(new DefExpr(Symboltable::finishFnDef($<fnsym>5, $13)));
    }
|
  isconstructor fname
    {
      $<fnsym>$ = Symboltable::startFnDef(new FnSymbol($2), true);
      $<fnsym>$->isConstructor = $1;
    }
                  fnretref fnrettype where
    {
      Symboltable::continueFnDef($<fnsym>3, new AList<ParamSymbol>(), $5, $4);
    }
                            function_body_stmt
    {
      $$ = new DefStmt(new DefExpr(Symboltable::finishFnDef($<fnsym>3, $8)));
    }
;


moduledecl:
  TMODULE identifier
    {
      $<modsym>$ = Symboltable::startModuleDef($2);
    }
                     TLCBR modulebody TRCBR
    {
      $$ = new DefStmt(Symboltable::finishModuleDef($<modsym>3, $5));
    }
;


decl:
  TWITH lvalue TSEMI
    { $$ = new WithStmt($2); }
| TUSE lvalue TSEMI
    { $$ = new UseStmt($2); }
| TWHERE whereexpr TSEMI
    { $$ = new ExprStmt($2); }
| vardecl
    { $$ = $1; }
| typedecl
| fndecl
| moduledecl
;


decls:
  /* empty */
    { $$ = new AList<Stmt>(); }
| decls pragmas decl
    {
      $3->pragmas = $2;
      $1->insertAtTail($3);
    }
;


tupleTypes:
  type
    {
      $$ = new TupleType();
      $$->addType($1);
    }
| tupleTypes TCOMMA type
    { 
      $$ = $1;
      $$->addType($3);
    }
;


tupleType:
  TLP tupleTypes TRP
    { $$ = $2; }
;


unresolvedType:
  unresolvedType TDOT identifier
    {
      $1->names->add($3);
    }
| identifier
    {
      Vec<char*>* new_names = new Vec<char*>();
      new_names->add($1);
      $$ = new UnresolvedType(new_names);
    }
;


type:
  domainType
| indexType
| arrayType
| seqType
| tupleType
| unresolvedType
    { $$ = $1; }
| query_identifier
    { $$ = dtUnknown; }
;

domainType:
  TDOMAIN
    { $$ = new DomainType(); }
| TDOMAIN TLP expr TRP
    { $$ = new DomainType($3); }
;


indexType:
  TINDEX
    { $$ = new IndexType(); }
| TINDEX TLP expr TRP
    { $$ = new IndexType($3); }
;


forallExpr:
  TLSBR nonemptyExprlist TRSBR
    { $$ = Symboltable::startForallExpr($2); }
| TLSBR nonemptyExprlist TIN nonemptyExprlist TRSBR
    { $$ = Symboltable::startForallExpr($4, $2); }
;


arrayType:
  TLSBR TRSBR type
    { $$ = new ArrayType(unknownDomain, $3); }
| TLSBR query_identifier TRSBR type
    { 
      Symboltable::defineQueryDomain($2);  // really need to tuck this into
                                           // a var def stmt to be inserted
                                           // as soon as the next stmt is
                                           // defined  -- BLC
      $$ = new ArrayType(unknownDomain, $4);
    }
| forallExpr type
    {
      Symboltable::finishForallExpr($1);
      $$ = new ArrayType($1, $2);
    }
;


seqType:
  TSEQ TOF type
    { $$ = new SeqType($3); }
| TSEQ TLP type TRP
    { $$ = new SeqType($3); }
;


statements:
  /* empty */
    { $$ = new AList<Stmt>(); }
| statements pragmas statement
    { 
      $3->pragmas = $2;
      $1->insertAtTail($3);
    }
;


function_body_single_stmt:
  noop_stmt
| conditional
| loop
| call_stmt
| retStmt
;


function_body_stmt:
  function_body_single_stmt
    { $$ = new BlockStmt(new AList<Stmt>($1)); }
| block_stmt
;


statement:
  noop_stmt
| TLABEL identifier statement
    { $$ = new LabelStmt(new LabelSymbol($2), 
           new BlockStmt(new AList<Stmt>($3))); }
| TGOTO identifier TSEMI
    { $$ = new GotoStmt(goto_normal, $2); }
| TBREAK identifier TSEMI
    { $$ = new GotoStmt(goto_break, $2); }
| TBREAK TSEMI
    { $$ = new GotoStmt(goto_break); }
| TCONTINUE identifier TSEMI
    { $$ = new GotoStmt(goto_continue, $2); }
| TCONTINUE TSEMI
    { $$ = new GotoStmt(goto_continue); }
| decl
| assignment
| conditional
| loop
| call_stmt
| lvalue TSEMI
    { $$ = new ExprStmt($1); }
| retStmt
| block_stmt
    { $$ = $1; }
| error
    { printf("syntax error"); exit(1); }
;


pragmas:
  /* empty */
    { $$ = NULL; }
| pragmas pragma
    {
      if ($1 == NULL) {
        $$ = new AList<Pragma>($2);
      } else {
        $1->insertAtTail($2);
      }
    }
;


pragma:
  TPRAGMA STRINGLITERAL
  { $$ = new Pragma($2); }
;


call_stmt:
  TCALL lvalue TSEMI
    { $$ = new ExprStmt($2); }
;


noop_stmt:
  TSEMI
    { $$ = new NoOpStmt(); }
;


block_stmt:
  TLCBR
    { $<blkstmt>$ = Symboltable::startCompoundStmt(); }
        statements TRCBR
    { $$ = Symboltable::finishCompoundStmt($<blkstmt>2, $3); }
;


retStmt:
  TRETURN TSEMI
    { $$ = new ReturnStmt(NULL); }
| TRETURN expr TSEMI
    { $$ = new ReturnStmt($2); }
;


fortype:
  TFOR
    { $$ = false; }
| TFORALL
    { $$ = true; }
;


indexes:
  ident_symbol
    { $$ = new AList<Symbol>($1); }
| indexes TCOMMA ident_symbol
    { $1->insertAtTail($3); }
;


indexlist:
  indexes
| TLP indexes TRP
  { $$ = $2; }
;


forloop:
  fortype indexlist TIN expr
    { 
      $<forstmt>$ = Symboltable::startForLoop($1, $2, $4);
    }
                             block_stmt
    { 
      $$ = Symboltable::finishForLoop($<forstmt>5, $6);
    }
| fortype indexlist TIN expr
    { 
      $<forstmt>$ = Symboltable::startForLoop($1, $2, $4);
    }
                             TDO statement
    { 
      $$ = Symboltable::finishForLoop($<forstmt>5, $7);
    }
| TLSBR indexlist TIN expr TRSBR
    { 
      $<forstmt>$ = Symboltable::startForLoop(true, $2, $4);
    }
                                 statement
    { 
      $$ = Symboltable::finishForLoop($<forstmt>6, $7);
    }
;


whileloop:
TWHILE expr TDO statement
    { $$ = new WhileLoopStmt(true, $2, new AList<Stmt>($4)); }
| TWHILE expr block_stmt
    { $$ = new WhileLoopStmt(true, $2, new AList<Stmt>($3)); }
| TDO statement TWHILE expr TSEMI
    { $$ = new WhileLoopStmt(false, $4, new AList<Stmt>($2)); }
;


loop:
  forloop
| whileloop
;


conditional:
  TIF expr block_stmt %prec TNOELSE
    { $$ = new CondStmt($2, dynamic_cast<BlockStmt*>($3)); }
| TIF expr TTHEN statement %prec TNOELSE
    { $$ = new CondStmt($2, new BlockStmt(new AList<Stmt>($4))); }
| TIF expr block_stmt TELSE statement
    { $$ = new CondStmt($2, dynamic_cast<BlockStmt*>($3), new BlockStmt(new AList<Stmt>($5))); }
| TIF expr TTHEN statement TELSE statement
    { $$ = new CondStmt($2, new BlockStmt(new AList<Stmt>($4)), new BlockStmt(new AList<Stmt>($6))); }
;


assignOp:
  TASSIGN
    { $$ = GETS_NORM; }
| TASSIGNPLUS
    { $$ = GETS_PLUS; }
| TASSIGNMINUS
    { $$ = GETS_MINUS; }
| TASSIGNMULTIPLY
    { $$ = GETS_MULT; }
| TASSIGNDIVIDE
    { $$ = GETS_DIV; }
| TASSIGNBAND
    { $$ = GETS_BITAND; }
| TASSIGNBOR
    { $$ = GETS_BITOR; }
| TASSIGNBXOR
    { $$ = GETS_BITXOR; }
;


assignExpr:
  lvalue assignOp expr
    { $$ = new AssignOp($2, $1, $3); }
;


assignment:
  assignExpr TSEMI
    { $$ = new ExprStmt($1); }
;


exprlist:
  /* empty */
    { $$ = new AList<Expr>(); }
| nonemptyExprlist
;


expr_list_item:
  identifier TASSIGN expr
    { $$ = new NamedExpr($1, $3); }
| expr
    { $$ = $1; }
;


nonemptyExprlist:
  pragmas expr_list_item
    { $2->pragmas = $1; $$ = new AList<Expr>($2); }
| nonemptyExprlist TCOMMA pragmas expr_list_item
    { $4->pragmas = $3; $1->insertAtTail($4); }
;


declarable_expr:
  identifier
    { $$ = new Variable(new UnresolvedSymbol($1)); }
| TLP nonemptyExprlist TRP 
    { 
      if ($2->length() == 1) {
        $$ = $2->popHead();
      } else {
        $$ = new Tuple($2);
      }
    }
;

lvalue:
  declarable_expr
| lvalue TDOT identifier
    { $$ = new MemberAccess($1, new UnresolvedSymbol($3)); }
| lvalue TLP exprlist TRP
    { $$ = new ParenOpExpr($1, $3); }
;


atom:
  literal
| lvalue
;


seq_expr:
  TSEQBEGIN exprlist TSEQEND
    { $$ = new SeqExpr($2); }
;


conditional_expr:
  TLP TIF expr TTHEN expr TELSE expr TRP
    {
      $$ = new CondExpr($3, $5, $7);
    }
;


expr: 
  atom
| TNIL
    { $$ = new Variable(Symboltable::lookupInternal("nil", SCOPE_INTRINSIC)); }
| TLET
    { $<pexpr>$ = Symboltable::startLetExpr(); }
       vardecl_inner_ls TIN expr
    { $$ = Symboltable::finishLetExpr($<pexpr>2, $3, $5); }
| reduction %prec TREDUCE
| expr TCOLON type
  { $$ = new CastExpr($3, $1); }
| expr TCOLON STRINGLITERAL
  { 
    Variable* _chpl_tostring =
      new Variable(new UnresolvedSymbol("_chpl_tostring"));
    AList<Expr>* args = new AList<Expr>($1);
    args->insertAtTail(new StringLiteral($3));
    $$ = new ParenOpExpr(_chpl_tostring, args);
  }
| range %prec TDOTDOT
| conditional_expr
| seq_expr
| forallExpr expr %prec TRSBR
    { $$ = Symboltable::finishForallExpr($1, $2); }
| TPLUS expr %prec TUPLUS
    { $$ = new UnOp(UNOP_PLUS, $2); }
| TMINUS expr %prec TUMINUS
    { $$ = new UnOp(UNOP_MINUS, $2); }
| TNOT expr
    { $$ = new UnOp(UNOP_LOGNOT, $2); }
| TBNOT expr
    { $$ = new UnOp(UNOP_BITNOT, $2); }
| expr TPLUS expr
    { $$ = Expr::newPlusMinus(BINOP_PLUS, $1, $3); }
| expr TMINUS expr
    { $$ = Expr::newPlusMinus(BINOP_MINUS, $1, $3); }
| expr TSTAR expr
    { $$ = new BinOp(BINOP_MULT, $1, $3); }
| expr TDIVIDE expr
    { $$ = new BinOp(BINOP_DIV, $1, $3); }
| expr TMOD expr
    { $$ = new BinOp(BINOP_MOD, $1, $3); }
| expr TEQUAL expr
    { $$ = new BinOp(BINOP_EQUAL, $1, $3); }
| expr TNOTEQUAL expr
    { $$ = new BinOp(BINOP_NEQUAL, $1, $3); }
| expr TLESSEQUAL expr
    { $$ = new BinOp(BINOP_LEQUAL, $1, $3); }
| expr TGREATEREQUAL expr
    { $$ = new BinOp(BINOP_GEQUAL, $1, $3); }
| expr TLESS expr
    { $$ = new BinOp(BINOP_LTHAN, $1, $3); }
| expr TGREATER expr
    { $$ = new BinOp(BINOP_GTHAN, $1, $3); }
| expr TBAND expr
    { $$ = new BinOp(BINOP_BITAND, $1, $3); }
| expr TBOR expr
    { $$ = new BinOp(BINOP_BITOR, $1, $3); }
| expr TBXOR expr
    { $$ = new BinOp(BINOP_BITXOR, $1, $3); }
| expr TAND expr
    { $$ = new BinOp(BINOP_LOGAND, $1, $3); }
| expr TOR expr
    { $$ = new BinOp(BINOP_LOGOR, $1, $3); }
| expr TEXP expr
    { $$ = new BinOp(BINOP_EXP, $1, $3); }
| expr TSEQCAT expr
    { $$ = new BinOp(BINOP_SEQCAT, $1, $3); }
| expr TBY expr
    { $$ = new SpecialBinOp(BINOP_BY, $1, $3); }
;

reduction:
  identifier TREDUCE expr
    { $$ = new ReduceExpr(new UnresolvedSymbol($1), $3); }
;


range:
  expr TDOTDOT expr
    { $$ = new SimpleSeqExpr($1, $3); }
| TSTAR
    { $$ = new FloodExpr(); }
| TDOTDOT
    { $$ = new CompleteDimExpr(); }
;


literal:
  INTLITERAL
    { $$ = new IntLiteral(yytext, atol(yytext)); }
| FLOATLITERAL
    { $$ = new FloatLiteral(yytext, atof(yytext)); }
| COMPLEXLITERAL
    { $$ = new ComplexLiteral(yytext, atof(yytext)); }
| STRINGLITERAL
    { $$ = new StringLiteral($1); }
;


identifier:
  TIDENT
    { $$ = copystring(yytext); }
;


opt_identifier:
    { $$ = NULL; }
| identifier;


query_identifier:
  QUERY_IDENT
    { $$ = copystring(yytext+1); }
;


%%
