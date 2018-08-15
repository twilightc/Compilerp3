%{
  #include<stdio.h>
  #include<iostream>
  #include<cmath>
  #include"symboltable.hpp"
  #include"lex.yy.c"
  #include"jcgenerate.hpp" 
  #define Trace(t) if(Opt_P) cout << "\nmessage:  " <<t << endl;
  bool IsMain = false;	//enter mainfc correctly
  int Opt_P = 1;
  int Opt_dump = 1;
  string Fnname = "";
  void yyerror(string s);	//trace error info at certainly line
  Symboltablelist stlist;
  vector<vector<Idata>> param_invo;	//paramter invocation
  ofstream out;
  string filename;
  
%}

%union{
  string* sval;
  Idata* idata;
  float fval;
  int ival;
  bool bval;
  int datatype; 
}

/* tokens*/ 

/* operator with 2 or more char*/
%token LE BE EQU NEQ AND OR ADDE SUBE MULE DEVE

/* ketword*/
%token BREAK CHAR CONTINUE DO ELSE ENUM EXTERN FOR FN 
%token IF IN LET LOOP MATCH MUT PRINT PRINTLN PUB RETURN SELF STATIC
%token STR STRUCT USE WHERE WHILE
%token READ

/* function return assign*/
%token ARROW;

/* variable*/
%token  INT FLOAT BOOL STRING 

/* const*/
%token <ival>CONST_INT
%token <fval>CONST_FLOAT
%token <bval>CONST_BOOL
%token <sval>CONST_STR

/* id*/
%token <sval>ID

/* Vn;non-determinal*/
%type <datatype>mut_type fn_type
%type <idata>expr constvalue fn_invocation

/* expression precedence*/
%left OR
%left AND
%left '!'
%left '<' LE EQU BE '>' NEQ
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%start program
%%
/* program starting*/
program: setprogram def_mut_optional def_func_optional 
	{
		if(!IsMain) cerr << "not found fn named \"main\" " << endl;
		Blockfinish();
		
	}
	;

setprogram:
	{
		setProgram();
	}
	;

/* variable definition(none/one/or more)*/
def_mut_optional: def_mut def_mut_optional
		|def_const def_mut_optional|;

/* variable and array*/
def_mut:LET MUT ID ';' 
	{
		Trace("mutable declaration");
		if(stlist.InsertMut(*$3) == -1) yyerror("ERROR: mutable declaration repeatedly");				
		//int index=stlist.getIndex(*$3);	
		int index = stlist.getIndex(*$3);
		if(index == -1){
			GlobalvarNI(*$3);
		}
		
	}
	|LET MUT ID ':' mut_type ';'
	{
		Trace("mutable with type declaration");
		if(stlist.Insert(*$3,$5) == -1) yyerror("ERROR: mutable declaration repeatedly");
		int index=stlist.getIndex(*$3);
		
		if(index == -1){
			GlobalvarNI(*$3);
		}
	}
	|LET MUT ID '=' expr ';'
	{
		Trace("mutable with value declaration");
		if(!isConst(*$5)) yyerror("ERROR: assignment's value cannot a nonconstant");
		$5->itype = idt_mut;
		if(stlist.InsertIdata(*$3,*$5) == -1) yyerror("ERROR: mutable declaration repeatedly"); 
		if($5->dtype == t_int || $5->dtype == t_bool){
			int value = ($5->dtype==t_int)?$5->iv.int_v:$5->iv.bool_v;
			int index = stlist.getIndex(*$3);
			if(index == -1){
				Globalvar(*$3,value);
			}else if(index != -87){
				cout << "HEREE?" << endl;
				Localvar(index,value);
			}
		}


	}
	|LET MUT ID ':' mut_type '=' expr ';'
	{
		Trace("mutable with type and value declaration");
		if($5 != $7->dtype) yyerror("ERROR: assign datatype cannot match");
		if(!isConst(*$7)) yyerror("ERROR: assignment's value cannot a nonconstant");
		$7->itype = idt_mut;
		if(stlist.InsertIdata(*$3,*$7) == -1) yyerror("ERROR: mutable declaration repeatedly");	
		if($7->dtype == t_int || $7->dtype == t_bool){
			int value = ($7->dtype==t_int)?$7->iv.int_v:$7->iv.bool_v;
			int index = stlist.getIndex(*$3);
			if(index == -1){
				Globalvar(*$3,value);
			}else if(index != -87){
				Localvar(index,value);
			}
		}
	}
	|LET MUT ID '[' mut_type ',' expr ']' ';'
	{
		Trace("array declaration");
		if($5 != t_int) yyerror("ERROR: array size should be a integer");
		if(!isConst(*$7)) yyerror("ERROR: array size should be constant");	
		if(stlist.InsertArray(*$3,$5,$7->iv.int_v) == -1)yyerror("ERROR: array declaration repeatly");

	}
	;

/* const*/
def_const:LET ID '=' expr ';' 
	{
		Trace("constant declaration");
		if(!isConst(*$4)) yyerror("ERROR: assign value cannot a nonconstant");
		$4->itype = idt_constmut;
		if(stlist.InsertIdata(*$2,*$4) == -1) yyerror("ERROE: Constant declaration repeatedly");
	}
	|LET ID ':' mut_type '=' expr ';' 
	{
		Trace("constant with type declaration");
		if($4 != $6->dtype) yyerror("ERROR: datatype cannot match");
		if(!isConst(*$6)) yyerror("ERROR: assign value cannot a nonconstant");
		$6->itype = idt_constmut;
		if(stlist.InsertIdata(*$2,*$6) == -1) yyerror("ERROR: Constant declaration repeatedly");
	}
	;

mut_type:STRING {$$ = t_str;}
	|INT	{$$ = t_int;}
	|FLOAT  {$$ = t_float;}
	|BOOL	{$$ = t_bool;}
	;

constvalue:CONST_INT   {$$ = Constint($1);}
	|CONST_BOOL  {$$ = Constbool($1);}
	|CONST_FLOAT {$$ = Constfloat($1);}
	|CONST_STR   {$$ = Conststring($1);}
	;

/* function definition*/
def_func_optional:def_func def_func_optional|;
		
def_func:marker_fn'(' def_para_pattern ')' has_arrow_ornot 
	 '{'
	def_mut_optional
	def_stmt
	 '}'
	{
		Trace("fn end, pop symboltable");
		Idata* ida = stlist.Lookuplist(Fnname);
		if(Fnname == "main") MainReturn();
		Blockfinish();
		
		if(Opt_dump==1 && Fnname == "main"){
			cout<<"\n"<<"main fn finished. dump symboltable"<<endl;
			stlist.Dumplist();
		}
		if(!stlist.listpop()) yyerror("ERROR: fail to pop the list");
	}
	;

marker_fn:FN ID
	{
		Trace("enter fn block,push a new symboltable");
		Fnname = *$2;
		if((*$2) == "main") {IsMain=true; setMain();}
		if(stlist.InsertFn(*$2,t_void) == -1) yyerror("ERROR: CANNOT DECLARE SAME FUNCTION NAME REPEATEDLY");
		stlist.listpush();	
	}

has_arrow_ornot:ASSIGN fn_type
	{		
		Trace("function with return value");
		Idata* ida = stlist.Lookuplist(Fnname);
		if(!ida) yyerror("ERROR: CANNOT FIND FN NAME");
		ida->dtype = $2;
		
		setFn(*ida);
	}|
	{
		Trace("function with no return");
	}
	;


ASSIGN:ARROW;

fn_type:STRING {$$ = t_str;}
	|INT	 {$$ = t_int;}
	|BOOL	 {$$ = t_bool;}
	|FLOAT	 {$$ = t_float;}
	;

/*zero or more parameter can be invocated*/
def_para_pattern:para_pattern|;

para_pattern:para|para ',' para;

para:ID ':' mut_type
	{
		if(stlist.Insert(*$1,$3) == -1) yyerror("ERROR: mutable declaration repeatedly");
		if(!stlist.setFnparameter(*$1,$3)) yyerror("ERROR: CANNOT SET PARAMETER CORRECTLY");
	} 
	;

/* declare statement*/
/* from here,any id after symboltablelist should be check is NULL or not*/
def_stmt:stmt_pattern def_stmt|stmt_pattern;

stmt_pattern:simple
	|block
	{
		Trace("statement with block");
	}
	|conditional
	{
		Trace("statement with conditional");
	}
	|loop
	{
		Trace("statement with loop");
	}
	|fn_invocation
	{
		Trace("statement with fn_invocation");
	}	
	;

simple:ID '=' expr ';'
	{
		Trace("statement with assign mutable value");
		Idata *ida = stlist.Lookuplist(*$1);
		if(ida == NULL) yyerror("ERROR: id not declare");
		if(ida->itype != idt_mut) yyerror("ERROR: only can assign value when id is mutable");
		if(ida->dtype == t_array) yyerror("ERROR: id not array type, lost an square brackets?");
		if(ida->dtype != $3->dtype) yyerror("ERROR: assign type cannot match");
		if(ida->dtype == t_int || ida->dtype == t_bool){
			int index = stlist.getIndex(*$1);
			if(index == -1){
				setGlobalvar(*$1);
			}else if(index != -87){
				setLocalvar(index);
			}
		}
	}
	|ID '[' expr ']' '=' expr ';'
	{
		Trace("statement with assign array value");
		Idata *ida = stlist.Lookuplist(*$1);
		if(ida == NULL) yyerror("ERROR: id not declare");
		if(ida->itype != idt_mut) yyerror("ERROR: array should by mutable");
		if(ida->dtype != t_array) yyerror("ERROR: not an array type");
		if($3->dtype != t_int) yyerror("ERROR: index should be integer");
		if($3->iv.array_v[0].dtype != $6->dtype) yyerror("ERROR: assign type cannot match");

	}
	|PRINT setprint expr ';' 
	{
		Trace("statement with print expr");
		if($3->dtype == t_int)
			Printintexpr();
		else
			Printstrexpr();
	}
	|PRINTLN setprint expr ';'
	{
		Trace("statement with println expr");
		if($3->dtype == t_int)
			Printlnintexpr();
		else
			Printlnstrexpr();
	}
	|READ ID ';'
	{
		Trace("statement with READ");
		Idata *ida = stlist.Lookuplist(*$2);
		if(ida == NULL) yyerror("ERROR: id not declare");
	}
	|RETURN ';'
	{
		Trace("statement with RETURN");
		Returnvoid();		
	}
	|RETURN expr ';'
	{
		Trace("statement with RETURN expr");
		Returnvalue();
	}
	;

setprint:
	{
		setPrint();
	}
	;

block:   marker_block   
	def_mut_optional
	def_stmt 
	'}'
	{
		Trace("block end, pop symboltable");
		//if(Opt_dump == 1)stlist.Dumplist();
		if(!stlist.listpop())yyerror("ERROR: fail to pop the list");
	}
	;

marker_block:'{' 
	{
		Trace("enter block, push a new symboltable");
		stlist.listpush();
	}
	;

/* if(bool_expr)*/
conditional:IF '(' expr ')' ifstart stmt_pattern ELSE elsestart stmt_pattern
	    {
		Trace("IF ELSE statement");
		if($3->dtype != t_bool)yyerror("ERROR: expr in condition not a boolean type");
		ifelseend();
	    }
	    |IF '(' expr ')' ifstart stmt_pattern
	    {
		Trace("IF statement");
		if($3->dtype != t_bool)yyerror("ERROR: expr in condition not a boolean type");
		ifend();
	    }
	    ;

ifstart:
	{
		ifstart();
	}
	;

elsestart:
	{
		elsestart();
	}
	;

loop:WHILE  whilestart '(' expr ')' whilebody stmt_pattern
	{
		Trace("While loop");
		if($4->dtype != t_bool) yyerror("ERROR: expr in condition not a boolean type");
		whileend();
	}
	;

whilestart:
	{
		whilestart();
	}
	;

whilebody:
	{
		whilebody();
	}


fn_invocation:ID '(' marker_fn_invocation comma_sep_expr ')' 
	{
		Trace("fn invocation");
		Idata *ida = stlist.Lookuplist(*$1);
		if(ida == NULL) yyerror("ERROR: fn not declare");
		if(ida->itype != idt_fn) yyerror("ERROR: ID is not a func");
		vector<Idata>checktype = ida->iv.array_v;
		/* check formal parameter match actual parameter or not*/
		if(checktype.size() != param_invo[param_invo.size()-1].size()) yyerror("invocate parameter amount cannot match");
		for(int i=0 ; i < checktype.size() ; i++){
			if(checktype.at(i).dtype != param_invo[param_invo.size()-1].at(i).dtype) yyerror("ERROR:invocate type cannot match");
		}

		FnInvocation(*ida);
		$$ = ida;
		param_invo.pop_back();
	}
	;

marker_fn_invocation:
	{
		param_invo.push_back(vector<Idata>());
	}
	;

/* invocate parameter or not*/
comma_sep_expr:invocate_expr|;

invocate_expr:para_expr ',' invocate_expr|para_expr;

para_expr:expr
	{
		param_invo[param_invo.size()-1].push_back(*$1);
	}
	;

expr:ID
     {
	Idata *ida = stlist.Lookuplist(*$1);
	if(ida == NULL) yyerror("ERROR: id not decalre");
	if(ida->itype == idt_constn) ida->itype = idt_constmut;
	$$ = ida;
	//1.variable 2.constant	
	if((ida->dtype == t_int || ida->dtype == t_bool) && !isConst(*ida)){
		int index = stlist.getIndex(*$1);
		if(index == -1){
			getGlobalvar(*$1);
		}else if(index != -87){
			getLocalvar(index);
		}
	}else if(isConst(*ida) && !stlist.checkscope()){
		if(ida->dtype == t_int || ida->dtype == t_bool){
			int value = (ida->dtype==t_int)?ida->iv.int_v:ida->iv.bool_v;	
			getConstint(value);
		}else if(ida->dtype == t_str){
			getConststr(ida->iv.str_v);
		}
	}	
     } 
     |constvalue
     {
	if(!stlist.checkscope()){
		if($1->dtype == t_int || $1->dtype == t_bool){
			int value = ($1->dtype==t_int)?$1->iv.int_v:$1->iv.bool_v;
			getConstint(value);
		}else if($1->dtype == t_str){
			getConststr($1->iv.str_v);
		}
	}
     }
     |fn_invocation 
     |'(' expr ')'
     {
	Trace("( expr )");
	$$ = $2;
     }
     |ID '[' expr']'
     {
	Idata *ida = stlist.Lookuplist(*$1);
	if($3->dtype != t_int) yyerror("ERROR: size must be a integer");
	$$ = new Idata(ida->iv.array_v[($3->iv.int_v)]);
     }
     |'-' expr	%prec UMINUS
     {
	Trace("-expr");
	//cout << $2->itype <<endl;
	if($2->dtype != t_int && $2->dtype != t_float) yyerror("ERROR: expr cannot use this operator");
	if($2->itype == idt_constn){
		if($2->dtype == t_int){			
			$$ = Constint($2->iv.int_v*(-1));
		}else if($2->dtype == t_float){
			$$ = Constfloat($2->iv.float_v*(-1));
		}
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = $2->dtype;	 
		ida->itype = idt_mut;	 
		$$ = ida;
	}
	if($2->dtype == t_int) Operation(NEG);
     }
     |expr '*' expr
     {
	Trace("expr * expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the * operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constint($1->iv.int_v*$3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constfloat($1->iv.float_v*$3->iv.float_v);
		}
	}else{
		Idata *ida = new Idata();
		ida->dtype = $1->dtype;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Operation(MUL);
     }
     |expr '/' expr
     {
	Trace("expr / expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the / operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			if($3->iv.int_v == 0) yyerror("ERROR: cannot devide into zero");
			$$ = Constint($1->iv.int_v/$3->iv.int_v);
		}else if($1->dtype == t_float){
			if($3->iv.float_v == 0.0) yyerror("ERROR: cannot devide into zero");
			$$ = Constfloat($1->iv.float_v/$3->iv.float_v);
		}
	}else{
		Idata *ida = new Idata();
		ida->dtype = $1->dtype;
		ida->itype = idt_mut;
		$$ = ida;
	}	
	if($1->dtype == t_int) Operation(DIV);
     }
     |expr '+' expr
     {
	Trace("expr + expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the + operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constint($1->iv.int_v+$3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constfloat($1->iv.float_v+$3->iv.float_v);
		}
	}else{
		Idata *ida = new Idata();
		ida->dtype = $1->dtype;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Operation(ADD);     
     }
     |expr '-' expr
     {
	Trace("expr - expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the - operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constint($1->iv.int_v-$3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constfloat($1->iv.float_v-$3->iv.float_v);
		}
	}else{
		Idata *ida = new Idata();
		ida->dtype = $1->dtype;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Operation(SUB);
     }
     |expr '<' expr
     {
	Trace("expr < expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the < operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v < $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v < $3->iv.float_v);
		}	
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFLT);
     }
     |expr LE expr
     {
	Trace("expr LE expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the LE  operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v <= $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v <= $3->iv.float_v);
		}	
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFLE);
     }
     |expr EQU expr
     {
	Trace("expr EQU expr");
	if($1->dtype != t_int && $1->dtype != t_float && $1->dtype != t_bool) yyerror("ERROR: this expr cannot use the EQU  operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");	
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v == $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v == $3->iv.float_v);
		}else if($1->dtype == t_bool){
			$$ = Constbool($1->iv.bool_v == $3->iv.bool_v);
		}		

	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFEQ);	
     }
     |expr BE expr
     {
	Trace("expr BE expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the BE operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v >= $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v >= $3->iv.float_v);
		}
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFGE);	
     }
     |expr '>' expr
     {
	Trace("expr > expr");
	if($1->dtype != t_int && $1->dtype != t_float) yyerror("ERROR: this expr cannot use the > operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v > $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v > $3->iv.float_v);
		}
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFGT);
     }
     |expr NEQ expr
     {
	Trace("expr NEQ expr");
	if($1->dtype != t_int && $1->dtype != t_float && $1->dtype != t_bool) yyerror("ERROR: this expr cannot use the NEQ  operator");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_int){
			$$ = Constbool($1->iv.int_v != $3->iv.int_v);
		}else if($1->dtype == t_float){
			$$ = Constbool($1->iv.float_v != $3->iv.float_v);
		}else if($1->dtype == t_bool){
			$$ = Constbool($1->iv.bool_v != $3->iv.bool_v);
		}
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Relationalop(IFNE);	
     }
     |'!' expr
     {
	Trace("!expr");
	if($2->dtype != t_bool) yyerror("ERROR: cannot use ! operator except boolean type");
	if($2->itype == idt_constn){
	
		$$ = Constbool(!($2->iv.bool_v));
	}else{
		Idata *ida = new Idata();
		ida->dtype = $2->dtype;	 
		ida->itype = idt_mut;	 
		$$ = ida;
	}
	if($2->dtype == t_int) Operation(IXOR);	
     }
     |expr AND expr
     {
	Trace("expr AND expr");
	
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_bool){
			$$ = Constbool($1->iv.bool_v && $3->iv.bool_v);
		}	
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Operation(IAND);
     }
     |expr OR expr
     {
	Trace("expr OR expr");
	if($1->dtype != $3->dtype) yyerror("ERROR: datatype mismatch");
	if($1->itype == $3->itype && $1->itype == idt_constn){
		if($1->dtype == t_bool){
			$$ = Constbool($1->iv.bool_v || $3->iv.bool_v);
		}	
		
	}else{
		Idata *ida = new Idata();
		ida->dtype = t_bool;
		ida->itype = idt_mut;
		$$ = ida;
	}
	if($1->dtype == t_int) Operation(IOR);
     }
     ;


%%
void yyerror(string s){
	cerr << "Line " << linecount << " "<< s << endl;
	exit(1);
}


main(int argc, char* argv[])
{
	
	yyin = fopen(argv[1],"r");
	if(!yyin){
		cout << "cannot open the file" << endl;
		exit(1);
	}

	//default: oldfilename.rust
	string oldfilename = argv[1];
	size_t dot = oldfilename.find(".");
	//check if can get the oldfilename
	//if so, retrieve it from oldfilename.rust
	if(dot != string::npos){
		filename = oldfilename.substr(0,dot);
 		out.open(filename + ".jasm");
		
	}else{
		cout << "cannot find target" << endl;
		exit(1);
	}

	yyparse();
	//cout<<"\n"<< "program finished. dump symboltable"<<endl;
	//stlist.Dumplist();
	return 0;
}

