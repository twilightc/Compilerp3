#include "jcgenerate.hpp"

labellist llist;

label::label(int m, int l)
{
	max = m;
	lcurrently = l;
}

labellist::labellist()
{
	llistcount = 0;
}

void labellist::pushllist(int amount)
{
	lcontainer.push_back(label(amount,llistcount));
	llistcount += amount;
}

void labellist::popllist()
{
	lcontainer.pop_back();
}


int labellist::getllist(int index)
{
	return lcontainer.at(lcontainer.size() - 1).lcurrently + index;
}

int labellist::getABEllist()
{
	llistcount++;
	return llistcount-1;	//index start from 0
}

void setProgram()
{
	out << "class " << filename << endl;
	out << "{" << endl;
}


void setMain()
{
	out << "method public static void main(java.lang.String[])" << endl;
	out << "max_stack 15" << endl;
	out << "max_locals 15" << endl;
	out << "{" << endl;
} 

void Blockfinish()
{
	out << "}" << endl;
}


void GlobalvarNI(string name)
{
	out << "field static int " << name << endl;
}

void Globalvar(string name,int value)
{
	out << "field static int " << name << "=" << value << endl;
}

void Localvar(int index,int value)
{
	out << "istore " << index << endl;
}

void getGlobalvar(string name)
{
	out << "getstatic int " << filename << "." << name << endl;
}

//loading from index
void getLocalvar(int index)
{
	out << "iload " << index << endl;
}

//boolean and int using same func
void getConstint(int value)
{
	out << "sipush " << value << endl;
}

void getConststr(string str)
{
	out << "ldc \"" << str << "\""<< endl;
}

void setLocalvar(int index)
{
	out << "istore " << index << endl;
}

//only integer will be considered
void setGlobalvar(string id)
{
	out << "putstatic int " << filename << "." << id << endl;
}



void setPrint()
{
	out << "getstatic java.io.PrintStream java.lang.System.out" << endl;
}

void Printintexpr()
{
	out << "invokevirtual void java.io.PrintStream.print(int)" << endl;
}


void Printstrexpr()
{
	out << "invokevirtual void java.io.PrintStream.print(java.lang.String)" << endl;
}


void Printlnintexpr()
{
	out << "invokevirtual void java.io.PrintStream.println(int)" << endl;
}

void Printlnstrexpr()
{
	out << "invokevirtual void java.io.PrintStream.println(java.lang.String)" << endl;
}


//arithmetic and boolean expr
void Operation(int op)
{
	switch(op){
		case ADD:
			out << "iadd" << endl;
			break;
		case SUB:
			out << "isub" << endl;
			break;
		case MUL:
			out << "imul" << endl;
			break;
		case DIV:
			out << "idiv" << endl;
			break;
		case REM:
			out << "irem" << endl;
			break;
		case NEG:
			out << "ineg" << endl;
			break;
		case IAND:
			out << "iand" << endl;
			break;
		case IOR:
			out << "ior" << endl;
			break;
		case IXOR:
			out << "ixor" << endl;
			break;
		default:
			break;
	}	
}


void Relationalop(int op)
{
	int l1=llist.getABEllist();
	int l2=llist.getABEllist();
	
	out << "isub" << endl;
	switch(op){
		case IFLT:
			out << "iflt";
			break;
		case IFGT:
			out << "ifgt";
			break;
		case IFEQ:
			out << "ifeq";
			break;
		case IFLE:
			out << "ifle";
			break;
		case IFGE:
			out << "ifge";
			break;
		case IFNE:
			out << "ifne";
			break;
		default:
			break;
	}
	out << " L" << l1 << endl;
	out << "iconst_0" << endl;
	out << "goto L" << l2 << endl;
	out << "L" << l1 << ":" <<  "iconst_1"<< endl;
	out << "L" << l2 << ":" << endl;
}


//former = 0
//latter = 1
void ifstart()
{
	llist.pushllist(2);
	out << "ifeq L" << llist.getllist(0) << endl;
	 
}

void ifend()
{
	out << "L" << llist.getllist(0) << ":" << endl;
	llist.popllist();
}

void elsestart()
{
	out << "goto L" << llist.getllist(1) << endl;
	out << "L" << llist.getllist(0) << ":" << endl;
}

void ifelseend()
{
	out << "L" << llist.getllist(1) << ":" << endl;
	llist.popllist();
}

void whilestart()
{
	llist.pushllist(2);
	out << "L" << llist.getllist(0) << ":" << endl;
}

void whilebody()
{
	out << "ifeq L" << llist.getllist(1) << endl;
}

void whileend()
{
	out << "goto L" << llist.getllist(0) << endl;
	out << "L" << llist.getllist(1) << ":" << endl;
	llist.popllist();
}


void setFn(Idata parameter)
{
	out << "method public static ";
	out << ((parameter.dtype == t_void)?"void":"int");
	out << " "<< parameter.name << "(";
	int parasize = parameter.iv.array_v.size();
	for(int i = 0; i< parasize; i++){
		out << "int";
		if(i != (parasize - 1)) out <<", ";
	}
	out << ")" << endl;
	out << "max_stack 15" << endl;
	out << "max_locals 15" << endl;
	out << "{" << endl;

}

void FnInvocation(Idata parameter)
{
	out << "invokestatic ";
	out << ((parameter.dtype == t_void)?"void":"int");
	out << " " << filename << "." << parameter.name << "(";
	int parasize = parameter.iv.array_v.size();
	for(int i = 0; i < parasize; i++){
		out << "int";
		if(i != (parasize - 1)) out << ", ";
	}
	out << ")" << endl;

}


void Returnvoid()
{
	out << "return" << endl;
}

void Returnvalue()
{
	out << "ireturn" << endl;
}

void MainReturn()
{
	out << "return" << endl;
}


