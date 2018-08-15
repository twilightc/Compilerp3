TARGET = parser
LEX = flex
YACC = bison
YACCFLAG = -y -d
CXX = g++
CXXFLAG = -std=c++11 

.PHONY:all clean

all: $(TARGET)

$(TARGET): lex.yy.c y.tab.c symboltable.cpp symboltable.hpp jcgenerate.cpp jcgenerate.hpp
	$(CXX)  $(CXXFLAG) y.tab.c symboltable.cpp jcgenerate.cpp -o $@ -ll -ly

lex.yy.c: lex.l
	$(LEX) -o $@ $^

y.tab.c: parser.y
	$(YACC) $(YACCFLAG) $^ -o $@

clean:
	$(RM) $(TARGET) lex.yy.c y.tab.*
