#include"symboltable.hpp"

/*Initialize*/
Idvalue::Idvalue(){
  str_v = "";
  int_v = 0;
  bool_v = false;
  float_v = 0.0;

}

Idata::Idata(){
  index = 0;
  dtype = t_int;
  itype = idt_mut;

}

Symboltable::Symboltable()
{
	index = 0;
}

int Symboltable::Insert(string sname,int datatype,int idtype,Idvalue idvalue)
{
	if(key.find(sname) == key.end()){
		key[sname].name = sname;	
		key[sname].index = index;
		key[sname].dtype = datatype;
		key[sname].itype = idtype;
		key[sname].iv = idvalue;
		id.push_back(sname);
		index +=1; //size become bigger but return size 
			    // shouldn't change(as index start from 0)		
		//cout<<"Insertindex"<<index<<endl;
		return index-1;
	}else{
		return -1; //collision
	}

}

//true:exist(collsion) false:not exist
bool Symboltable::Exist(string s)
{
	return (key.find(s) != key.end())?true:false;
}

Idata* Symboltable::Lookup(string s)
{
	if(Exist(s)){
		return &key[s]; 
	}else{
		return NULL;
	}
}

Idata* Symboltable::Lookupptr(string s)
{
	if(Exist(s)){
		Idata* idata = &key[s];
		return idata;
	}else return NULL;	//not in the table
}

int Symboltable::Dump()
{
	//cout<<"DDDDUMP  indexsize:"<<index<<endl;
	for(int i = 0; i < index; i++){
		Idata ida = key[id[i]];	//match the id's name inside the key
		cout << i << "\t" << retrieveIdainfo(ida) << endl;
	} 
	return id.size();
}

int Symboltable::getIndex(string s)
{
	if(Exist(s)){
		return key[s].index;
	}else{
		return 0;
	}	
}

int Symboltable::getSize()
{
	return id.size();
}

/*symboltable list*/
Symboltablelist::Symboltablelist()
{
	top = -1;	
	listpush();
}

//create new table into tablelist
void Symboltablelist::listpush()
{
	list.push_back(Symboltable());
	top += 1;
}

bool Symboltablelist::listpop()
{
	if(list.size() <= 0)
		return false;
	list.pop_back();
	top--;
	return true;
}

Idata* Symboltablelist::Lookuplist(string e)
{
	for(int i = top; i >= 0 ; i--){
		if(list[i].Exist(e)){
			return list[i].Lookup(e);  //copy and return 
		}
	}
	return NULL; 	//not int the list
}

int Symboltablelist::Dumplist()
{
	cout << "Symboltablelist:" << endl;
	for(int i = top; i >= 0; i--){
		cout << "table " << i << ":" <<endl;
		list[i].Dump();
	}

	return list.size();
}

//true = global
bool Symboltablelist::checkscope()
{
	return(top == 0)?true:false;
}

//-1 = not found
int Symboltablelist::getIndex(string name)
{
	for(int i = top ; i >= 0 ; i--){
		if(list[i].Exist(name)){
			if(i == 0){
				return -1;
			}else{	
				int localindex=0;
				localindex += list[i].getIndex(name);
				for(int j=1 ; j<i;j++){
					localindex += list[j].getIndex(name);
				}
				//cout <<"LOCALINDEX:"<<localindex<<endl;
				return localindex;
			}
		}
	}
	return -87;
}

/* insert mutable*/
int Symboltablelist::InsertMut(string name)
{
	return list[top].Insert(name,t_int,idt_mut,Idvalue());
}

/* insert mutable with type*/
int Symboltablelist::Insert(string name,int datatype)
{
	return list[top].Insert(name,datatype,idt_mut,Idvalue());
}

/* insert mutable with type and value*/
int Symboltablelist::InsertIdata(string name,Idata i)
{
	//cout<< name<<":"<<i.itype<<endl;
	return list[top].Insert(name,i.dtype,i.itype,i.iv);
}

/* insert array*/
int Symboltablelist::InsertArray(string name,int datatype,int size)
{
	Idvalue idv;
	idv.array_v = vector<Idata>(size);
	for(int i = 0;i < size;i++){
		idv.array_v[i].dtype = datatype;	
		idv.array_v[i].itype = idt_mut;
		idv.array_v[i].index = -1;	//no element so far
	}
	return list[top].Insert(name,t_array,idt_mut,idv);
}

/* insert function*/
int Symboltablelist::InsertFn(string name,int datatype)
{
	fnname = name;		//record current fn name
	return list[top].Insert(name,datatype,idt_fn,Idvalue());
}

bool Symboltablelist::setFnparameter(string name,int datatype)
{
	/*search name where the scope call the function
	  if not get, return false*/
	Idata *temp = list[top-1].Lookupptr(fnname);
	if(temp == NULL) return false;	
	
	Idata ida;
	ida.name = name;
	ida.dtype = datatype;
	ida.itype = idt_mut;
	/* set parameter info*/
	temp->iv.array_v.push_back(ida);	
	return true;
}

bool isConst(Idata ida)
{
	if((ida.itype != idt_constmut) && (ida.itype != idt_constn))
		return false;
	else return true;
}


/* encapsulate a constvalue into a id*/
Idata* Constint(int i)
{
	Idata *ida = new Idata();
	ida->index = 0;
	ida->dtype = t_int;
	ida->itype = idt_constn;
	ida->iv.int_v = i;
	return ida;
}

Idata* Constbool(bool b)
{
	Idata *ida = new Idata();
	ida->index = 0;
	ida->dtype = t_bool;
	ida->itype = idt_constn;
	ida->iv.bool_v = b;
	return ida;
}

Idata* Constfloat(float f)
{
	Idata *ida = new Idata();
	ida->index = 0;
	ida->dtype = t_float;
	ida->itype = idt_constn;
	ida->iv.float_v = f;
	return ida; 
}

Idata* Conststring(string* s)
{
	Idata *ida = new Idata();
	ida->index = 0;
	ida->dtype = t_str;
	ida->itype = idt_constn;
	ida->iv.str_v = *s;
	return ida;
}

string retrieveDtype(int dtype)
{
	switch(dtype){
		case t_str:
			return "str";
		case t_int:
			return "int";
		case t_bool:
			return "bool";
		case t_float:
			return "float";
		case t_array:
			return "array";
		default:
			return "Cannot retrieve Dtype";
	}
}

string retrieveIdvalue(Idvalue idv,int dtype)
{
	switch(dtype){
		case t_str:
			return idv.str_v;
		case t_int:
			return to_string(idv.int_v);
		case t_bool:
			return to_string(idv.bool_v);
		case t_float:
			return to_string(idv.float_v);
		case t_array:
			return to_string(idv.array_v.size());
		default:
			return "Cannot retrieve Itype";
	}
}

//e.g. (a:int, b:int)
string retrieveFnparam(vector<Idata> p)
{
	string str_p=" ";
	for(int i = 0;i<p.size();i++){
		if(i > 0) str_p += ", ";
		str_p += p[i].name + ":" + retrieveDtype(p[i].dtype); 
	}
	return str_p;
}

//e.g. fn add(a:int, b:int)
string retrieveFninfo(Idata ida)
{
	if(ida.itype != idt_fn) return "Not a function";
	if(ida.dtype == t_void)
		return "fn " + ida.name + "(" + retrieveFnparam(ida.iv.array_v) + ")";
	else
		return "fn " + ida.name + "(" + retrieveFnparam(ida.iv.array_v) + ")" + "->" + retrieveDtype(ida.dtype);	
}

//e.g. let mut a:int = 10
//     let a:float = 9.0
//     let mut a[int, 100]
string retrieveIdainfo(Idata ida)
{
	string str=" ";
	switch (ida.itype){
		case idt_mut:
			str += "mut";
			break; 
		case idt_constmut:
			//plus nothing, see e.g. above
			break;
		case idt_fn:
			str += retrieveFninfo(ida);
			return str;;
		default:
			return "Cannot retrieve ida:" + ida.name + "'s information";
	}
	if(ida.dtype == t_array){
		str+= " " + ida.name + "[" + retrieveDtype(ida.iv.array_v[0].dtype) + "," + retrieveIdvalue(ida.iv,ida.dtype) +"]" + "\n";
	}else{
		str += " " + ida.name + ":" + retrieveDtype(ida.dtype) + "=" + retrieveIdvalue(ida.iv,ida.dtype) + "\n";
	}
	return str;
}
