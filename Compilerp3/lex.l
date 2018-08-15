%{
  #include<iostream>
  #include<vector>
  #include<map>
  #include"y.tab.h"
  using namespace std;
  #define MAX_LINE_LENG 256
  #define LIST strcat(buf,yytext)
  #define token(t)  {LIST; if(ptk)printf("<%s>\n",#t);}
  #define tokenInteger(t,i)  {LIST; if(ptk)printf("<%s:%d>\n",t,i);}
  #define tokenString(t,s)  {LIST; if(ptk)printf("<%s:%s>\n",t,s);}

  int linecount = 1;
  char buf[MAX_LINE_LENG];
  char str[MAX_LINE_LENG];
  FILE *fn;
  int ptk = 0;	//switch that print token or not(default:not)
  
%}

ws [ \t]+
alpha [A-Za-z]
digit [0-9]
identifier {alpha}({digit}|{alpha})*
digits {digit}+
double {digits}\.{digits}
exp_real {digits}\.{digits}[Ee][+-]?{digits}
real {double}|{exp_real}

%x S		
%x COMMENT
%x MINUSORRETURN

%%

[ \t]* {LIST;}

"," {token(','); return yytext[0];}

":" {token(':'); return yytext[0];}

";" {token(';'); return yytext[0];}

"(" {token('('); return yytext[0];}

")" {token(')'); return yytext[0];}

"[" {token('['); return yytext[0];}

"]" {token(']'); return yytext[0];}

"{" {token('{'); return yytext[0];}

"}" {token('}'); return yytext[0];}

"+" {token('+'); return yytext[0];}

"*" {token('*'); return yytext[0];}

"/" {token('/'); return yytext[0];}

"%" {token('%'); return yytext[0];}

"<" {token('<'); return yytext[0];}

">" {token('>'); return yytext[0];}

"<=" {token('<='); return LE;}

"=>" {token('=>'); return BE;}

"==" {token('=='); return EQU;}

"!=" {token('!='); return NEQ;}

"&&" {token('&&'); return AND;}

"||" {token('||'); return OR;}

"!" {token('!');return yytext[0]; }

"=" {token('='); return yytext[0];}

"-" {token('-'); return yytext[0];}

"->" {token('->'); return ARROW;}

"+=" {token('+='); return ADDE;}

"-=" {token('-='); return SUBE;}

"*=" {token('*='); return MULE;}

"/=" {token('/='); return DEVE;}

"bool" {token(bool); return BOOL;}

"break" {token(break); return BREAK;}

"char" {token(char); return CHAR;}

"continue" {token(continue); return CONTINUE;}

"do" {token(do); return DO;}

"else" {token(else); return ELSE;}

"enum" {token(enum); return ENUM;}

"extern" {token(extern); return EXTERN;}

"float" {token(float); return FLOAT;}

"for" {token(for); return FOR;}

"fn" {token(fn); return FN;}

"if" {token(if); return IF;}

"in" {token(in); return IN;}

"int" {token(int); return INT;}

"let" {token(let); return LET;}

"loop" {token(loop); return LOOP;}

"match" {token(match); return MATCH;}

"mut" {token(mut); return MUT;}

"print" {token(print); return PRINT;}

"println" {token(println); return PRINTLN;}

"pub" {token(pub); return PUB;}

"return" {token(return); return RETURN;}

"self" {token(self); return SELF;}

"static" {token(static); return STATIC;}

"str" {token(str); return STR;}

"struct" {token(struct); return STRUCT;}

"use" {token(use); return USE;}

"where" {token(where); return WHERE;}

"while" {token(while); return WHILE;}

"true" {
	tokenString("boolean","TRUE");
	yylval.bval = true;
	return CONST_BOOL;
}

"false" {
	tokenString("boolean","FALSE");
	yylval.bval = false;
	return CONST_BOOL;
}

{digits} {tokenString("integer",yytext);
	  yylval.ival = atoi(yytext);
	  return CONST_INT;
}

{real} {tokenString("real",yytext);
	yylval.fval = atof(yytext);	
	return CONST_FLOAT;
}

{identifier} {
	tokenString("id:",yytext);
	yylval.sval = new string(yytext);	
	return ID;
}	


\n {
	LIST;
	printf("%d: %s",linecount++,buf);
	buf[0] = '\0';	
}
 

\" {
	LIST;
	str[0] = '\0';
	BEGIN S;	
}

<S>\" {
	char c = yyinput();
	if(c == '"'){
		strcat(buf,"\"\"");
		strcat(str,"\"");
	}else{
		strcat(buf,"\"");
		if(ptk)printf("<%s: %s>\n","String",str);
		unput(c);
		BEGIN INITIAL;
		yylval.sval = new string(str);
		return CONST_STR;
	}	

}

<S>[^"\n]* {
	LIST;
	strcat(str,yytext);
}

"//"[^\n]* {
	LIST;
}

"/*" {
	LIST;
	BEGIN COMMENT;
}

<COMMENT>\n {
	LIST;
	printf("%d: %s\n",linecount++,buf);
	buf[0] = '\0';
}

<COMMENT>"*/" {
	LIST;
	BEGIN INITIAL;
}

<COMMENT>. {
	LIST;
}


"*/" {
	LIST;
}

. {
	LIST;
	printf("%d:%s\n",linecount++,buf);
	printf("bad character:'%s'\n",yytext);
	exit(-1);
}

%%


