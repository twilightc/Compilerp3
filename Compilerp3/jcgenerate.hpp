#ifndef _JCGENERATE_H_ 
#define _JCGENERATE_H_

#include<stdio.h>
#include<iostream>
#include<fstream>
#include<vector>
#include<string>
#include"symboltable.hpp"


extern ofstream out;
extern string filename;


enum abeop{ADD,SUB,MUL,DIV,REM,NEG,IAND,IOR,IXOR};
enum relationalop{IFLT,IFGT,IFEQ,IFLE,IFGE,IFNE};

struct label{
	int max;
	int lcurrently;	//label's amount in the time
	
	label(int m, int l);
}; 

class labellist{
private:
	int llistcount;
public:
	vector<label> lcontainer;	//label container
	labellist();
	void pushllist(int amount);
	void popllist();
	int getllist(int index);
	int getABEllist();	//arithmetic and boolean label

};

//initial
void setProgram();
void setMain();
void Blockfinish();


void Globalvar(string name,int value);
void GlobalvarNI(string name);  //gloval var that no initialize
void Localvar(int index, int value);

//expression
void getGlobalvar(string name);
void getLocalvar(int index);
void getConstint(int value);
void getConststr(string str);
void setLocalvar(int index);
void setGlobalvar(string id);

//print
void setPrint();
void Printintexpr();
void Printstrexpr();
void Printlnintexpr();
void Printlnstrexpr();

//operation part
void Operation(int op);
void Relationalop(int op);

//IF
void ifstart();
void ifend();
void elsestart();
void ifelseend();

//WHILE
void whilestart();
void whilebody();
void whileend();


//FN part
void setFn(Idata parameter);	//only int
void FnInvocation(Idata pameter);
void Fnfinish();


void Returnvoid();
void Returnvalue();	//return nothing
void MainReturn();




#endif
