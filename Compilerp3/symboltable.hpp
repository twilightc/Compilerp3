#ifndef _SYMBOLTABLE_H_
#define _SYMBOLTABLE_H_

#include<stdio.h>
#include<iostream>
#include<string>
#include<vector>
#include<map>

using namespace std;

enum Datatype{
	t_str,
	t_int,
	t_bool,
	t_float,
	t_array,
	t_void
};

enum Idtype{
	idt_mut,	//mutable name
	idt_constn,	//const number value(e.g. 123)
	idt_constmut,	//const mut value(e.g. let a = 123)
	idt_fn	//function

};

enum Varscope{
	global,
	local
};

/*construct value */
struct Idata;
struct Idvalue{
	string str_v;
	int int_v;
	bool bool_v;
	float float_v;
	vector<Idata> array_v;	

	Idvalue();	//constructer
};

/*construct id's data*/
struct Idata{
	string name;	//id's name
	int index;
	int dtype;	//id's datatype	
	int itype;	//id's IDtype
	Idvalue iv;	//dtype's value

	Idata();	//constructer
};

/*change : int to Idata to save type*/
class Symboltable{
  private:
        map<string,Idata> key;
        vector<string> id;      
        int index;
  public:
        Symboltable();
        int Insert(string s,int datatype,int idtype,Idvalue id);
        Idata* Lookup(string s);
        int Dump();
	Idata* Lookupptr(string s);    //return address if need
	bool Exist(string s);	       //whether variable in this scope
	int getIndex(string s);
	int getSize();
};


/*save symboltable
  distinct variable from different scope*/
class Symboltablelist{
  private:
	int top;
	vector<Symboltable> list;
	string fnname;		//currently function's name	

  public:
	Symboltablelist();
	void listpush();	//push table into list	
	bool listpop();		//pop table form list
	Idata* Lookuplist(string name);	//look around symboltable
	int Dumplist();
	
	bool checkscope();	//true = global
	int getIndex(string name);

	int InsertMut(string name_id);
	int Insert(string name_id,int type);		
	int InsertIdata(string name_id,Idata i);
	int InsertArray(string name_id,int type,int size);
	int InsertFn(string name_id,int type);
	bool setFnparameter(string name_id,int type);

};

bool isConst(Idata);

/* create const value with data information*/
Idata* Constint(int i);
Idata* Constbool(bool b);
Idata* Constfloat(float f);
Idata* Conststring(string* s);

/* retrieve all infomation(string) when dump the list*/
string retrieveDtype(int dtype);
string retrieveIdvalue(Idvalue idv,int dtype);
string retrieveFninfo(Idata ida);
string retrieveIdainfo(Idata ida);
string retrieveFnparam(vector<Idata>);


#endif
