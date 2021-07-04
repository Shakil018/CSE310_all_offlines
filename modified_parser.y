%{
#include<iostream>
#include<stdio.h>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include<algorithm>
#include<vector>
#include<string>
#include"SymbolTable.cpp"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

SymbolTable *symboltable;

int line_count=1;
int error_count = 0;

int label_count=0;
int temp_count=0;



FILE *in_file;
FILE *log_file;
FILE *error_file;

FILE *code_file;
FILE *optimized_file;






string newLabel()
{
	
	string label = "L";
	label += to_string(label_count);

	label_count++;

	return label;


	// char *lb= new char[4];
	// strcpy(lb,"L");
	// char b[3];
	// sprintf(b,"%d", labelCount);
	// labelCount++;
	// strcat(lb,b);
	// return lb;
}

string newTemp()
{
	string temp = "t";
	temp += to_string(temp_count);

	temp_count++;


	cout<<endl<<"new temp is : "<<temp<<endl;


	return temp;

	// char *t= new char[4];
	// strcpy(t,"t");
	// char b[3];
	// sprintf(b,"%d", tempCount);
	// tempCount++;
	// strcat(t,b);
	// return t;
	
}



struct VarInfo{
	string var_name, var_type; // "var", "arr", "func_defn", "func_decl"
	string self_type;
	int var_size;

};

VarInfo temp_var;
Parameter temp_param;

vector<VarInfo> var_dec_list;
vector<Parameter> param_list;
vector<string> arg_list;

vector<string> send_arg_list;
vector<string> receive_arg_list;


vector<string> data_segment;
bool valid_func = false;


string id_name, id_type, id_name_last, id_type_last;



void yyerror(char *s)
{

	//fprintf(log_file, "Line no: %d %s\n\n", line_count, s);

	//line_count++;
	//error_count++;
}

void insert_func(VarInfo var)
{
	SymbolInfo *symbol = new SymbolInfo(var.var_name, "ID");
	symbol->setVarType(var.var_type);
	symbol->setSelfType(var.self_type);

	for(int i=0; i<param_list.size(); i++)
	{
		symbol->addParam(param_list[i].param_name, param_list[i].param_type);
	}

	symboltable->InsertSymbolObj(symbol);
}


string insert_variable(VarInfo var)
{
	SymbolInfo *symbol = new SymbolInfo(var.var_name, "ID");

	symbol->setVarType(var.var_type);
	symbol->setSelfType(var.self_type);
	symbol->setVarSize(var.var_size);
	
	
	string asm_var_name = var.var_name;

	asm_var_name += symboltable->get_string_id_asm();

	symbol->setSymbol(asm_var_name);

	if(var.var_type == "var")
	{
		data_segment.push_back(asm_var_name + " dw ?");
	}
	else if(var.var_type == "arr") {

		asm_var_name += " dw ";
		asm_var_name += to_string(var.var_size) + " dup (?)";


		data_segment.push_back(asm_var_name);

		cout<<"ARRAY:  "<<data_segment.back()<<endl;

	}


	
	symboltable->InsertSymbolObj(symbol);

	return asm_var_name;

	//printf("insert_var : %s %s %s\n", var.var_name.c_str(), var.var_type.c_str(), var.self_type.c_str());



}

/*

%union {SymbolInfo* symbolinfo; int ivar;}

%type <symbolinfo> start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments


*/


%}







%token IF ELSE FOR WHILE INT FLOAT DOUBLE CHAR RETURN VOID PRINTLN
%token SEMICOLON COMMA LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD INCOP DECOP ASSIGNOP NOT
%token CONST_INT CONST_FLOAT ID ADDOP MULOP RELOP LOGICOP
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE



%%
start : program {
		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		
		//fprintf(log_file, "Line ", dfdfdfddfdfdfdfddfdfdf)

		fprintf(log_file, "Line %d: start : program\n\n", line_count);
	
		// fprintf(log_file, "%s\n\n", $1->getName().c_str());

	
		if(error_count == 0)
		{
			string asm_code = "";
			asm_code = ".model medium\n.stack 100h\n.data\n\n";

			for(int i = 0; i < data_segment.size(); i++){
				asm_code += "\t" + data_segment[i] + "\n";
			} 

			data_segment.clear();

			asm_code += "\n\tmem_add dw 0\n\tnum dw ?\n\tmultiplier dw 10d\n";
			asm_code += "\n\tNEWLINE DB 0DH, 0AH, '$'\n";

			asm_code += "\n.code\n\n";
			asm_code += $1->code;


			asm_code += "\n\n; println proc begins\n\n";

			asm_code += "println proc\n";
			asm_code += "\tpop mem_add\n\tpop num\n";
			asm_code += "\tpush ax\n\t push bx\n\t push cx\n\t push dx\n";

			asm_code += "\tmov cx, 0d\n\tmov bx, num\ntest num, 8000h\n\tjz push_stack\n\tneg bx\n"; 
			asm_code += "push_stack:\n\tmov ax, bx\npush_stack_flow:\n";
			asm_code += "\txor dx, dx\n\tdiv multiplier\n\tmov bx, ax\n\tpush dx\n\tinc cx\n\tcmp bx, 0d\n\tjz check_sign\n\tjmp push_stack\n\n";
			asm_code += "check_sign:\n\ttest num, 8000h\n\tjz print_num\n\tmov ah, 2\n\tmov dl, '-'\n\tint 21h\n";
			asm_code += "print_num:\n\tcmp cx, 0d\n\tjz print_proc_end\n\tpop bx\n\t dec cx\n";
			asm_code += "\tmov ah, 2\n\tadd bx, 30h\n\tmov dx, bx\n\tint 21h\n\tjmp print_num\n";
			asm_code +=  "print_proc_end:\n\tlea dx, NEWLINE\n\t mov ah, 9\n\tint 21h\n";
			asm_code += "\n\t pop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tpush mem_add\n\tret\n\nprintln endp\n\n";

			asm_code += "end main\n";

			$$->code += asm_code;
			fprintf(code_file, "%s", $$->code.c_str());
			//fprintf(optimized_file, "%s", $$->optimized_code.c_str() );


		}

		delete $1;

	}
	;

program : program unit {
		$$ = new SymbolInfo($1->getName() + $2->getName(), "PRODUCTION_RULE");
		
		fprintf(log_file, "Line %d: program : program unit\n\n", line_count);
		fprintf(log_file, "%s %s\n\n", $1->getName().c_str(), $2->getName().c_str());

		$$->code += $1->code + $2->code;


	}

	| unit {
		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: program : unit\n\n", line_count);
		fprintf(log_file, "%s\n\n", $1->getName().c_str());


		$$->code += $1->code;

	}



	;

unit : var_declaration {
		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unit : var_declaration\n\n", line_count);
		fprintf(log_file, "%s\n\n", $1->getName().c_str());


	}
     | func_declaration {
     		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unit : func_declaration\n\n", line_count);
		fprintf(log_file, "%s\n\n", $1->getName().c_str());

     }
     | func_definition {
     		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unit : func_definition\n\n", line_count);
		fprintf(log_file, "%s\n\n", $1->getName().c_str());

		$$->code += $1->code;

     }
     ;

func_declaration : type_specifier id id_name_type LPAREN parameter_list RPAREN SEMICOLON {
		$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $5->getName() + ");" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n", line_count);



		SymbolInfo* temp = symboltable->lookup($2->getName());
            	if(temp != NULL) {
            	        fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $2->getName().c_str() );
            			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $2->getName().c_str() );
                		error_count++;
            	} else {

            		temp_var.var_name = $2->getName();
            		temp_var.self_type = $1->getName();
            		temp_var.var_type = "func_decl";
            		temp_var.var_size = -1;

                	insert_func(temp_var);
            	}



		param_list.clear();

		fprintf(log_file, "%s %s(%s);\n\n", $1->getName().c_str(), $2->getName().c_str(), $5->getName().c_str() );
	}
		| type_specifier id id_name_type LPAREN RPAREN SEMICOLON {

		$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "();" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n\n", line_count);




		SymbolInfo* temp = symboltable->lookup($2->getName());
            	if(temp != NULL) {
            	    fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $2->getName().c_str() );

            		fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $2->getName().c_str() );
                	error_count++;
            	} else {

            		temp_var.var_name = $2->getName();
            		temp_var.self_type = $1->getName();
            		temp_var.var_type = "func_decl";
            		temp_var.var_size = -1;


                	insert_func(temp_var);
            	}



		param_list.clear();

		fprintf(log_file, "%s %s();\n\n", $1->getName().c_str(), $2->getName().c_str() );
	}
		;

func_definition : type_specifier id id_name_type LPAREN parameter_list RPAREN func_check compound_statement {


		$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "(" + $5->getName() + ")" + $8->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n", line_count);

		fprintf(log_file, "%s %s(%s)%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $5->getName().c_str(), $8->getName().c_str() );





		if($2->getName() == "main" && valid_func)
		{


			$$->code += "\n\t; main proc begins here\n\n";


			$$->code += "main proc\n\tmov ax, @data\n\tmov ds, ax\n\n";
			$$->code += $8->code;
			$$->code += "\n\tmov ah, 4ch\n\tint 21h\n\nmain  endp\n";

			valid_func = false;
		}

		else{

			if(valid_func)
			{

				$$->code += "\n\t; " + $2->getName() + " proc begins here\n\n";


				$$->code += $2->getName() + " proc\n\t pop mem_add\n";

				for(int i = receive_arg_list.size()-1; i >= 0; i--){
					$$->code += "\tpop " + receive_arg_list[i] + "\n"; 
				}

				$$->code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n";	

				$$->code += $8->code;

				$$->code += "\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\n\tpush mem_add\n\tret\n";

				$$->code += $2->getName() + " endp\n\n";


			}

		}

		valid_func = false;
		receive_arg_list.clear();





	}
		| type_specifier id id_name_type LPAREN RPAREN func_check compound_statement {

		$$ = new SymbolInfo($1->getName() + " " + $2->getName() + "()" + $7->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: func_definition : type_specifier ID LPAREN RPAREN compound_statement\n\n", line_count);

		fprintf(log_file, "%s %s()%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $7->getName().c_str() );


		if($2->getName() == "main" && valid_func)
		{


			$$->code += "\n\t; main proc begins here\n\n";


			$$->code += "main proc\n\tmov ax, @data\n\tmov ds, ax\n\n";
			$$->code += $7->code;
			$$->code += "\n\tmov ah, 4ch\n\tint 21h\n\nmain endp\n\n";

			valid_func = false;
		}

		else{

			if(valid_func)
			{

				$$->code += "\n\t; " + $2->getName() + " proc begins here\n\n";


				$$->code += $2->getName() + " proc\n\t pop mem_add\n";

				$$->code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n";	

				$$->code += $7->code;

				$$->code += "\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\n\tpush mem_add\n\tret\n";

				$$->code += $2->getName() + " endp\n\n";


			}

		}

		valid_func = false;
		receive_arg_list.clear();


	}
 		;


id_name_type : {

		id_name_last = id_name;
		id_type_last = id_type;
	}

	;


func_check : {

		SymbolInfo *temp = symboltable->lookup(id_name_last);


		temp_var.var_name = id_name_last;
		temp_var.self_type = id_type_last;
            	temp_var.var_size = -1;


		if(temp == NULL)
		{
			printf("%s is null", id_name_last.c_str());
		 	temp_var.var_type = "func_defn";
			insert_func(temp_var);

			valid_func = true;
		}
		else if(temp->getVarType() == "var" || temp->getVarType() == "arr" || temp->getVarType() == "func_defn")
		{
			fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, id_name_last.c_str() );

			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, id_name_last.c_str() );
            error_count++;
		}
		else{

			if(temp->getSelfType() != id_type_last )
			{

				fprintf(log_file, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, id_name_last.c_str() );

				fprintf(error_file, "Error at line %d: Return type mismatch with function declaration in function %s\n\n", line_count, id_name_last.c_str() );
                error_count++;
			}

			else if(temp->getParamLen() == 1 && param_list.size() == 0 && temp->getParamAt(0).param_type == "void")
			{
				temp->setVarType("func_defn");
				valid_func = true;
			}
			else if(temp->getParamLen() == 0 && param_list.size() == 1 && param_list[0].param_type == "void")
			{
				temp->setVarType("func_defn");
				valid_func = true;
			}

			else if(temp->getParamLen() != param_list.size() )
			{
				fprintf(log_file, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, id_name_last.c_str() );

				fprintf(error_file, "Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n", line_count, id_name_last.c_str() );
                		error_count++;
			}
			else{

				int i;
				bool mismatch = false;

				for(i = 0; i < param_list.size(); i++)
				{
					if(param_list[i].param_type != temp->getParamAt(i).param_type)
					{
						mismatch = true;
						break;
					}
				}

				if(mismatch){
					fprintf(log_file, "Error at line %d: Inconsistent function definition with its declaration for %s\n\n", line_count, id_name_last.c_str() );

					fprintf(error_file, "Error at line %d: Inconsistent function definition with its declaration for %s\n\n", line_count, id_name_last.c_str() );
                	error_count++;

				}
				else{
					temp->setVarType("func_defn");
					
					valid_func = true;

				}
			}

		}


	}

	;

parameter_list : parameter_list COMMA type_specifier ID {

		$$ = new SymbolInfo($1->getName() + "," + $3->getName() + " " + $4->getName(), "PRODUCTION_RULE");


		temp_param.param_name = $4->getName();
		temp_param.param_type = $3->getName();

		bool mismatch = false;


		for(int i = 0; i < param_list.size(); i++){

			if(param_list[i].param_name == temp_param.param_name){
				fprintf(log_file, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, temp_param.param_name.c_str());
				fprintf(error_file, "Error at line %d: Multiple declaration of %s in parameter\n\n", line_count, temp_param.param_name.c_str());

				error_count++;
				mismatch = true;
				break;
			}
		}

		if(!mismatch){
			param_list.push_back(temp_param);
		}


		fprintf(log_file, "Line %d: parameter_list : parameter_list COMMA type_specifier ID\n\n", line_count);

		fprintf(log_file, "%s,%s %s\n\n", $1->getName().c_str(), $3->getName().c_str(), $4->getName().c_str() );




	}
		| parameter_list COMMA type_specifier {

		$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "PRODUCTION_RULE");

		temp_param.param_name = "";
		temp_param.param_type = $3->getName();

		bool mismatch = false;

		if(temp_param.param_type == "void"){
			fprintf(log_file, "Error at line %d: Parameter type cannot be void\n\n", line_count);
			fprintf(error_file, "Error at line %d: Parameter type cannot be void\n\n", line_count);

			error_count++;
			mismatch = true;
		}

		if(!mismatch){
			param_list.push_back(temp_param);
		}


		fprintf(log_file, "Line %d: parameter_list : parameter_list COMMA type_specifier\n\n", line_count);

		fprintf(log_file, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str() );









	}
 		| type_specifier ID {

 		$$ = new SymbolInfo($1->getName() + " " + $2->getName(), "PRODUCTION_RULE");

		temp_param.param_name = $2->getName();
		temp_param.param_type = $1->getName();

		bool mismatch = false;

		if(temp_param.param_type == "void"){
			fprintf(log_file, "Error at line %d: Parameter type cannot be void\n\n", line_count);
			fprintf(error_file, "Error at line %d: Parameter type cannot be void\n\n", line_count);

			error_count++;
			mismatch = true;
		}

		if(!mismatch){
			param_list.push_back(temp_param);
		}

		fprintf(log_file, "Line %d: parameter_list : type_specifier ID\n\n", line_count);

		fprintf(log_file, "%s %s\n\n", $1->getName().c_str(), $2->getName().c_str() );




 	}
		| type_specifier {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: parameter_list : type_specifier\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		temp_param.param_name = "";
		temp_param.param_type = $1->getName();

		param_list.push_back(temp_param);


	}
 		;


compound_statement : LCURL scope_in statements RCURL {

		$$ = new SymbolInfo("{" + (string)"\n" + $3->getName() + "}" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: compound_statement : LCURL statements RCURL\n\n", line_count);

		fprintf(log_file, "{\n%s\n}\n\n", $3->getName().c_str() );


		symboltable->print_all(log_file);
		symboltable->exitScope();

		$$->code += $3->code;



	}
 		    | LCURL scope_in RCURL {

		$$ = new SymbolInfo("{}" + (string)"\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: compound_statement : LCURL RCURL\n\n", line_count);

		fprintf(log_file, "{}\n\n" );


		symboltable->print_all(log_file);
		symboltable->exitScope();


	}
 		    ;



scope_in : {

		symboltable->enterScope();


		for(int i=0; i<param_list.size(); i++)
		{
			if(param_list[0].param_type == "void")
			{
				break;
			}

			temp_var.var_name = param_list[i].param_name;
			temp_var.self_type = param_list[i].param_type;
			temp_var.var_type = "var";
			temp_var.var_size = -1;


			string asm_var_name = insert_variable(temp_var);

			receive_arg_list.push_back(asm_var_name);

		}

		param_list.clear();

	}

	;





var_declaration : type_specifier declaration_list SEMICOLON {

		$$ = new SymbolInfo($1->getName() + " " + $2->getName() + ";" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: var_declaration : type_specifier declaration_list SEMICOLON\n\n", line_count);



		string self_type = $1->getName();
		printf("\ntype : %s, dec_list: %s\n", self_type.c_str(), $2->getName().c_str());

		if($1->getName() == "void")
		{
			fprintf(log_file, "Error at line %d: Variable type cannot be void\n\n", line_count);

			fprintf(error_file, "Error at line %d: Variable type cannot be void\n\n", line_count);
                	error_count++;

                	/*
                	for(int i=0; i<var_dec_list.size(); i++) {
                		var_dec_list[i].self_type = "int";
                    		insert_variable(var_dec_list[i]);
                	}
                	*/

		}
		else{
			for(int i=0; i<var_dec_list.size(); i++){
			        var_dec_list[i].self_type = self_type;
			        printf("inside for type: %s", self_type.c_str());
				insert_variable(var_dec_list[i]);
			}
		}

		var_dec_list.clear();

		fprintf(log_file, "%s %s;\n\n", $1->getName().c_str(), $2->getName().c_str() );


	}
 		 ;

id: ID {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            id_name = $1->getName();
    }
        ;

type_specifier	: INT {

		$$ = new SymbolInfo("int", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: type_specifier : INT\n\n", line_count);

		fprintf(log_file, "int\n\n");

		id_type = "int";
	}
 		| FLOAT {

 		$$ = new SymbolInfo("float", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: type_specifier : FLOAT\n\n", line_count);

		fprintf(log_file, "float\n\n");

		id_type = "float";
 	}
 		| VOID {

 		$$ = new SymbolInfo("void", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: type_specifier : VOID\n\n", line_count);

		fprintf(log_file, "void\n\n");

		id_type = "void";
 	}
 		;




declaration_list : declaration_list COMMA ID {

		$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "PRODUCTION_RULE");


		SymbolInfo *symbol = symboltable->lookup_current($3->getName());

		bool mismatch = false;


		if(symbol != NULL){
			fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );

			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );
            		error_count++;
            		mismatch = true;

		}
		

		for(int i = 0; i < var_dec_list.size(); i++){
			if($3->getName() == var_dec_list[i].var_name){
				fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );

				fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );
            			error_count++;
            			mismatch = true;
            			break;

			}
		}

			
		if(!mismatch){
			temp_var.var_name = $3->getName();
			temp_var.self_type = "";
			temp_var.var_type = "var";
			temp_var.var_size = -1;


			var_dec_list.push_back(temp_var);
		}

		


		fprintf(log_file, "Line %d: declaration_list : declaration_list COMMA ID\n\n", line_count);
		fprintf(log_file, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str() );


	}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {

		$$ = new SymbolInfo($1->getName() + "," + $3->getName() + "[" + $5->getName() + "]", "PRODUCTION_RULE");


		SymbolInfo *symbol = symboltable->lookup_current($3->getName());


		bool mismatch = false;

		if(symbol != NULL){
			fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );

			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );
                	error_count++;
                	mismatch = true;

		}
		

		for(int i = 0; i < var_dec_list.size(); i++){
			if($3->getName() == var_dec_list[i].var_name){
				fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );

				fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $3->getName().c_str() );
            			error_count++;
            			mismatch = true;
            			break;

			}
		}

			
		if(!mismatch){
		
		    	stringstream temp_str((string)$5->getName());
		    	int temp_size;

		    	temp_str>>temp_size;

			temp_var.var_name = $3->getName();
			temp_var.self_type = "";
			temp_var.var_type = "arr";
			temp_var.var_size = temp_size;


			var_dec_list.push_back(temp_var);

		}

		fprintf(log_file, "Line %d: declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n", line_count);
		fprintf(log_file, "%s,%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str(), $5->getName().c_str() );

	}
 		  | ID {

 		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");

		SymbolInfo *symbol = symboltable->lookup_current($1->getName());

		if(symbol != NULL){
			fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $1->getName().c_str() );
			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $1->getName().c_str() );
                	error_count++;

		}
		else{
			temp_var.var_name = $1->getName();
			temp_var.self_type = "";
			temp_var.var_type = "var";
			temp_var.var_size = -1;


			var_dec_list.push_back(temp_var);

			
		}
		
		


		fprintf(log_file, "Line %d: declaration_list : ID\n\n", line_count);
		fprintf(log_file, "%s\n\n", $1->getName().c_str() );


	}
 		  | ID LTHIRD CONST_INT RTHIRD {

		$$ = new SymbolInfo($1->getName() + "[" + $3->getName() + "]", "PRODUCTION_RULE");




		SymbolInfo *symbol = symboltable->lookup_current($1->getName());

		if(symbol != NULL){
			fprintf(log_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $1->getName().c_str() );

			fprintf(error_file, "Error at line %d: Multiple declaration of %s\n\n", line_count, $1->getName().c_str() );
                	error_count++;

		}
		
		else{
			stringstream temp_str((string)$3->getName());
			int temp_size;
		   
			temp_str>>temp_size;
		    
			temp_var.var_name = $1->getName();
			temp_var.self_type = "";
			temp_var.var_type = "arr";
			temp_var.var_size = temp_size;
	
			var_dec_list.push_back(temp_var);

				
		}

		

		fprintf(log_file, "Line %d: declaration_list : ID LTHIRD CONST_INT RTHIRD\n\n", line_count);
		fprintf(log_file, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str() );


	}
 		  ;

statements : statement {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statements : statement\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		if(error_count == 0)
		{
			$$->code += $1->code;
		}

	}
	   | statements statement {

		$$ = new SymbolInfo($1->getName() + $2->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statements : statements statement\n\n", line_count);

		fprintf(log_file, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str() );

		if(error_count == 0)
		{
			$$->code += $1->code + $2->code;
		}



	}
	   ;

statement : var_declaration {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : var_declaration\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

	}
	  | expression_statement {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : expression_statement\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += $1->code;
		}


	}
	  | compound_statement {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : compound_statement\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		if(error_count == 0)
		{
			$$->code += $1->code;
		}


	}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement {


		string exp1 = $3->getName(), exp2 = $4->getName(), exp3 = $5->getName();
		if (!exp1.empty()) {
        		exp1.pop_back();
    		}
    		if (!exp2.empty()) {
        		exp2.pop_back();
    		}


		$$ = new SymbolInfo("for(" + exp1 + exp2 + exp3 + ")" + $7->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n", line_count);



		if($3->getSelfType() == "void" || $4->getSelfType() == "void" || $5->getSelfType() == "void")
		{
			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
            error_count++;
		}




		fprintf(log_file, "for(%s%s%s) %s\n\n", exp1.c_str(), exp2.c_str(), exp3.c_str(), $7->getName().c_str() );


		if(error_count == 0 && $4->getName() != ";" && $5->getName() != ";")
		{
			$$->code += "; for(" + $3->getName() + "; " + $4->getName() + "; " + $5->getName() + ")\n";

			string loop_label = newLabel();
			string exit_label = newLabel();

			string condition = $4->getName().substr(0, $4->getName().size()-1);

			$$->code += $3->code;

			$$->code += loop_label + ":\n";
			$$->code += $4->code;
			$$->code += "\tmov ax, " + $4->getSymbol() + "\n";
			$$->code += "\tcmp ax, 0\n";
			$$->code += "\tje " + exit_label + "\n";
			$$->code += $7->code;

			$$->code += $5->code;
			$$->code += "\tjmp " + loop_label + "\n";

			$$->code += exit_label + ":\n";

			

		}





	}
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE {

		$$ = new SymbolInfo("if (" + $3->getName() + ")" + $5->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : IF LPAREN expression RPAREN statement\n\n", line_count);


		

		if($3->getSelfType() == "void")
		{
			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
            error_count++;
		}

		fprintf(log_file, "if (%s)%s\n\n", $3->getName().c_str(), $5->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += "; if(" + $3->getName() + ")\n"; 


			string exit_label = newLabel();

			$$->code += $3->code;
			$$->code += "\tmov ax, "+$3->getSymbol()+"\n";
			$$->code += "\tcmp ax, 1\n";
			$$->code += "jne "+ exit_label +"\n";
			$$->code += $5->code;
			$$->code += exit_label +":\n";
			
			// $$->setSymbol("if"); //not necessary

		}



	}
	  | IF LPAREN expression RPAREN statement ELSE statement {

		$$ = new SymbolInfo("if (" + $3->getName() + ")" + $5->getName() + "else" + (string)"\n" + $7->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : IF LPAREN expression RPAREN statement ELSE statement\n\n", line_count);


		if($3->getSelfType() == "void")
		{
			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
                	error_count++;
		}

		fprintf(log_file, "if (%s)%s else\n%s\n\n", $3->getName().c_str(), $5->getName().c_str(), $7->getName().c_str());

		if(error_count == 0)
		{
			string exit_label = newLabel();
			string else_label = newLabel();


			$$->code += "; if(" + $3->getName() + ")\n"; 

			$$->code += $3->code;
			$$->code += "\tmov ax, "+$3->getSymbol()+"\n";
			$$->code += "\tcmp ax, 1\n";
			$$->code += "\tjne " + else_label +"\n";
			$$->code += $5->code;
			$$->code += "\tjmp " + exit_label + "\n";
			$$->code += else_label + ":\n";
			$$->code += $7->code;
			$$->code += exit_label + ":\n";
			

		}




	}
	  | WHILE LPAREN expression RPAREN statement {

		$$ = new SymbolInfo("while (" + $3->getName() + ")" + $5->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : WHILE LPAREN expression RPAREN statement\n\n", line_count);


		if($3->getSelfType() == "void")
		{
			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
                	error_count++;
		}

		fprintf(log_file, "while (%s)%s\n\n", $3->getName().c_str(), $5->getName().c_str());


		if(error_count == 0)
		{
			string loop_label = newLabel();
			string exit_label = newLabel();


			$$->code += loop_label + ":\n";
			$$->code += $3->code;

			$$->code += "\tmov ax, " + $3->getSymbol() + "\n\tcmp ax, 0\n\tje " + exit_label + "\n";
			$$->code += $5->code;
			$$->code += "\tjmp " + loop_label + "\n" + exit_label + ":\n";

		}



	}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {

		$$ = new SymbolInfo("printf(" + $3->getName() + ");" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n\n", line_count);


		SymbolInfo *symbol = symboltable->lookup($3->getName());

		string argument_pass = "";

		if(symbol == NULL)
		{
			fprintf(log_file, "Error at line %d: Undeclared variable %s\n\n", line_count, $3->getName().c_str() );
			fprintf(error_file, "Error at line %d: Undeclared variable %s\n\n", line_count, $3->getName().c_str() );

			error_count++;

		}
		else{
			if(symbol->getSelfType() != "void")
			{
				argument_pass = symbol->getSymbol();
			}
		}

		$$->setSelfType("int");
		
		fprintf(log_file, "printf(%s);\n\n", $3->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += "\tpush " + argument_pass + "\n\tcall println\n";
		}


	}
	  | RETURN expression SEMICOLON {

		$$ = new SymbolInfo("return " + $2->getName() + ";" + "\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: statement : RETURN expression SEMICOLON\n\n", line_count);


		if($2->getSelfType() == "void")
		{

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
                	error_count++;
		}

		fprintf(log_file, "return %s;\n\n", $2->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += $2->code;
			$$->code += "\tpush " + $2->getSymbol() + "\n";
		}


	}
	  ;

expression_statement 	: SEMICOLON {

		$$ = new SymbolInfo(";" + (string)"\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: expression_statement : SEMICOLON\n\n", line_count);

		fprintf(log_file, ";\n\n");

		string self_type = "int";  	// default for all non type values

		$$->setSelfType(self_type);

		$$->setSymbol(";");

	}
			| expression SEMICOLON {

		$$ = new SymbolInfo($1->getName() + ";"  + (string)"\n", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: expression_statement : expression SEMICOLON\n\n", line_count);

		fprintf(log_file, "%s;\n\n", $1->getName().c_str() );

		string self_type = $1->getSelfType();

		$$->setSelfType(self_type);

		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());

	}
			;

variable : ID {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: variable : ID\n\n", line_count);


		SymbolInfo *symbol = symboltable->lookup($1->getName());

		$$->setVarType("var");


		if(symbol == NULL)
		{
			fprintf(log_file, "Error at line %d: Undeclared variable %s\n\n", line_count, $1->getName().c_str() );
			fprintf(error_file, "Error at line %d: Undeclared variable %s\n\n", line_count, $1->getName().c_str() );

			error_count++;
			$$->setSelfType("int");    //default for all undelcared types

		}
		else {
			if(symbol->getVarType() != "var"){
				if(symbol->getVarType() == "arr"){
					fprintf(log_file, "Error at line %d: Type mismatch, %s is an array\n\n", line_count, $1->getName().c_str() );

					fprintf(error_file, "Error at line %d: Type mismatch, %s is an array\n\n", line_count, $1->getName().c_str() );
					error_count++;


				}
				else if(symbol->getVarType() == "func_defn" || symbol->getVarType() == "func_decl" ){

					fprintf(log_file, "Error at line %d: Type mismatch, %s is a function\n\n", line_count, $1->getName().c_str() );

					fprintf(error_file, "Error at line %d: Type mismatch, %s is a function\n\n", line_count, $1->getName().c_str() );
					error_count++;
				}

				$$->setSelfType(symbol->getSelfType());
			}
			else{
				if(symbol->getSelfType() == "void"){
					$$->setSelfType("int");
				}
				else{
					$$->setSelfType(symbol->getSelfType());
					$$->setSymbol(symbol->getSymbol());

					cout<<"the symbol is : "<<symbol->getSymbol()<<endl;

				}
			}

		}

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

	}
	 | ID LTHIRD expression RTHIRD {

		$$ = new SymbolInfo((string)$1->getName() + "[" + (string)$3->getName() + "]", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: variable : ID LTHIRD expression RTHIRD\n\n", line_count);


		SymbolInfo *symbol = symboltable->lookup($1->getName());
		$$->setVarType("arr");


		if(symbol == NULL)
		{
			fprintf(log_file, "Error at line %d: Undeclared array %s\n\n", line_count, $1->getName().c_str() );


			fprintf(error_file, "Error at line %d: Undeclared array %s\n\n", line_count, $1->getName().c_str() );
			error_count++;
			$$->setSelfType("int");    //default for all undelcared types
			
			$$->setVarSize(0);


		}
		else{
			string var_type = symbol->getVarType();

			if(var_type != "arr"){
				fprintf(log_file, "Error at line %d: %s not an array\n\n", line_count, $1->getName().c_str() );

				fprintf(error_file, "Error at line %d: %s not an array\n\n", line_count, $1->getName().c_str() );
				error_count++;
			}
			else{

				if($3->getSelfType() != "int"){

					fprintf(log_file, "Error at line %d: Expression inside third brackets not an integer\n\n", line_count);

					fprintf(error_file, "Error at line %d: Expression inside third brackets not an integer\n\n", line_count);
					error_count++;
				}

			}

			if(symbol->getSelfType() == "void"){
				$$->setSelfType("int");
				$$->setVarSize(0);
			}
			else{
				$$->setSelfType(symbol->getSelfType());
				$$->setVarSize(symbol->getVarSize());
				$$->setSymbol(symbol->getSymbol());

			}
		}

		fprintf(log_file, "%s[%s]\n\n", $1->getName().c_str(), $3->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += $3->code;
			$$->code += "\n\tmov si, " + $3->getSymbol() + "\n\tadd si, si\n";

		}



	}
	 ;

 expression : logic_expression {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: expression : logic_expression\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());

		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());


	}
	   | variable ASSIGNOP logic_expression {

		$$ = new SymbolInfo($1->getName() + "=" + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: expression : variable ASSIGNOP logic_expression\n\n", line_count);


		cout<<"assigning " + $1->getName() + " = " + $3->getName()<<endl;
		cout<<"vars er symbol "<<$1->getSymbol()<<endl;
		cout<<"logics exp er getSymbol : "<<$3->getSymbol()<<", code: "<<$3->code<<endl;

		if($3->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
			error_count++;
			$3->setSelfType("int");
		}



		if($1->getSelfType() != $3->getSelfType()){

			if($1->getSelfType() == "int" && $3->getSelfType() == "float"){
				fprintf(log_file, "Error at line %d: Type Mismatch\n\n", line_count, $1->getName().c_str());

				fprintf(error_file, "Error at line %d: Type Mismatch\n\n", line_count, $1->getName().c_str());
				error_count++;

			}
		}



		$$->setSelfType($1->getSelfType());

		fprintf(log_file, "%s=%s\n\n", $1->getName().c_str(), $3->getName().c_str() );



		cout<<"vars getvartype : " + $1->getVarType()<<endl;

		if(error_count == 0)
		{
			if($1->getVarType() == "var")
			{
				cout<<"variable is var"<<endl;

				$$->code += $1->code + $3->code;
				$$->code += "\n\tmov bx, " + $3->getSymbol() + "\n";
				$$->code += "\tmov " + $1->getSymbol() + ", bx\n";
				$$->setSymbol($1->getSymbol());

			}
			else if($1->getVarType() == "arr")
			{
				string temp_asm_var = newTemp();
				data_segment.push_back(temp_asm_var + " dw ?");
				$$->code += $3->code + $1->code + "\mov bx, " + $3->getSymbol() + "\n";
				$$->code += "\mov " + $1->getSymbol() + "[si], bx\n\t mov " + temp_asm_var + ", bx\n";
				$$->setSymbol(temp_asm_var);
			}
		}



	}
	   ;

logic_expression : rel_expression {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: logic_expression : rel_expression\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());

		$$->setSymbol($1->getSymbol());
		$$->code += $1->code;


	}
		 | rel_expression LOGICOP rel_expression {

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: logic_expression : rel_expression LOGICOP rel_expression\n\n", line_count);




		if($1->getSelfType() == "void"){


			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;
		}

		if($3->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);


			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;
		}

		$$->setSelfType("int");


		fprintf(log_file, "%s%s%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $3->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += $1->code + $3->code;

			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");


			string true_false_label = newLabel();
			string exit_label = newLabel();


			if($2->getName() == "||")
			{
				$$->code += "\n\tmov ax, " + $1->getSymbol() + "\n\tcmp ax, 0\n\tjne "+true_false_label + "\n";
				$$->code += "\tmov ax, " + $3->getSymbol() + "\n\tcmp ax, 0\n\tjne " + true_false_label + "\n";
				$$->code += "\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += true_false_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ":\n";
			}
			else if($2->getName() == "&&")
			{
				$$->code += "\n\tmov ax, " + $1->getSymbol() + "\n\tcmp ax, 0\n\tje " + true_false_label + "\n";
				$$->code += "\tmov ax, " + $3->getSymbol() + "\n\tcmp ax, 0\n\tje " + true_false_label + "\n";
				$$->code += "\tmov " + temp_asm_var + ", 1\n\tjmp " + exit_label + "\n";
				$$->code += true_false_label + ": \n\tmov " + temp_asm_var + ", 0\n" + exit_label + ":\n";
			}

			$$->setSymbol(temp_asm_var);
		}

	}
		 ;

rel_expression	: simple_expression {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: rel_expression : simple_expression\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());

		$$->code += $1->code;
		
		$$->setSymbol($1->getSymbol());

	}
		| simple_expression RELOP simple_expression {

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: rel_expression : simple_expression RELOP simple_expression\n\n", line_count);



		if($1->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n", line_count);


			fprintf(error_file, "Error at line %d: Void function used in expression\n", line_count);
               		error_count++;
		}

		if($3->getSelfType() == "void"){
			fprintf(log_file, "Error at line %d: Void function used in expression\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n", line_count);
               		error_count++;
		}


		$$->setSelfType("int");

		fprintf(log_file, "%s%s%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $3->getName().c_str() );






		if(error_count == 0)
		{



			$$->code += $1->code + $3->code;
			$$->code += "\n\tmov ax, " + $1->getSymbol() + "\n\tmov bx, " + $3->getSymbol() + "\n";
			$$->code += "\tcmp ax, bx\n";

			string jmp_label = newLabel();
			string exit_label = newLabel();
			string temp_asm_var = newTemp();

			data_segment.push_back(temp_asm_var + " dw ?");


			if($2->getName() == ">")
			{
				$$->code += "\tjg " + jmp_label + "\n\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += jmp_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ": \n";
			}
			else if($2->getName() == ">=")
			{
				$$->code += "\jge " + jmp_label + "\n\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += jmp_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ": \n";

			}
			else if($2->getName() == "<")
			{
				$$->code += "\tjl " + jmp_label + "\n\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += jmp_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ": \n";
			}
			else if($2->getName() == "<=")
			{
				$$->code += "\tjle " + jmp_label + "\n\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += jmp_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ": \n";
			}
			else if($2->getName() == "!=")
			{
				$$->code += "\tjne " + jmp_label + "\n\tmov " + temp_asm_var + ", 0\n\tjmp " + exit_label + "\n";
				$$->code += jmp_label + ": \n\tmov " + temp_asm_var + ", 1\n" + exit_label + ": \n";
			}

			$$->setSymbol(temp_asm_var);

		}



	}
		;

simple_expression : term {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: simple_expression : term\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());


		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());

	}
		  | simple_expression ADDOP term {

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: simple_expression : simple_expression ADDOP term\n\n", line_count);




		if($1->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);


			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;

               		$1->setSelfType("int");
		}

		if($3->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;
               		$3->setSelfType("int");
		}

		if($1->getSelfType() == "float" || $3->getSelfType() == "float")
		{
			$$->setSelfType("float");
		}
		else{
			$$->setSelfType("int");
		}

		fprintf(log_file, "%s%s%s\n\n", $1->getName().c_str(), $2->getName().c_str(), $3->getName().c_str() );






		if(error_count == 0)
		{

			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");


			$$->code += $1->code + $3->code;

			$$->code += "\n\tmov ax, " + $1->getSymbol() + "\n"; 
			
			if($2->getName() == "+")
			{
				$$->code += "\tadd ax, " + $3->getSymbol() + "\n\tmov " + temp_asm_var + ", ax\n";
			}
			else
			{
				$$->code += "\tsub ax, " + $3->getSymbol() + "\n\tmov " + temp_asm_var + ", ax\n";
			}

			$$->setSymbol(temp_asm_var);
		}


	}
		  ;

term :	unary_expression {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: term : unary_expression\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());


		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());

	}
     |  term MULOP unary_expression {

		$$ = new SymbolInfo($1->getName() + $2->getName() + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: term : term MULOP unary_expression\n\n", line_count);


		if($1->getSelfType() == "void"){


			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;

               		$1->setSelfType("int");
		}

		if($3->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;
               		$3->setSelfType("int");
		}


		float temp_float = std::atof($3->getName().c_str()), epsilon = 1e-8;


		if($2->getName() == "/" && temp_float < epsilon){
			
			printf("IT WORKED, ZERO DETECTED\n\n\n");
			
			fprintf(log_file, "Error at line %d: Division by Zero\n\n", line_count);
			fprintf(error_file, "Error at line %d: Division by Zero\n\n", line_count);
			
			error_count++;
			
		}
		
		if($2->getName() == "%" && temp_float < epsilon){
			
			printf("IT WORKED, ZERO DETECTED\n\n\n");
			
			fprintf(log_file, "Error at line %d: Modulus by Zero\n\n", line_count);
			fprintf(error_file, "Error at line %d: Modulus by Zero\n\n", line_count);
			
			error_count++;
			
		}
		
		


		if($2->getName() == "%" && ($1->getSelfType() != "int" || $3->getSelfType() != "int") ){

			fprintf(log_file, "Error at line %d: Non-Integer operand on modulus operator\n\n", line_count);

			fprintf(error_file, "Error at line %d: Non-Integer operand on modulus operator\n\n", line_count);
			error_count++;
		}
		
		if($2->getName() == "%"){
			$$->setSelfType("int");
		}
		else if($2->getName() == "/"){
			$$->setSelfType("float");
		}
		else if($1->getSelfType() == "float" || $3->getSelfType() == "float")
		{
			$$->setSelfType("float");
		}
		else{
			$$->setSelfType("int");
		}

		fprintf(log_file, "%s%s%s\n\n", $1->getName().c_str(),  $2->getName().c_str(), $3->getName().c_str() );




		if(error_count == 0)
		{
			
			$$->code += $1->code + $3->code;

			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");

			if($2->getName() == "*")
			{
				$$->code += "\tmov ax, " + $1->getSymbol() + "\n\tmov bx, " + $3->getSymbol() + "\n\timul bx\n";
				$$->code += "\tmov " + temp_asm_var + ", ax\n";
			}
			else if($2->getName() == "/")
			{
				$$->code += "\tmov ax, " + $1->getSymbol() + "\n\tcwd\n";
				$$->code += "\tmov bx, " + $3->getSymbol();
				$$->code += "\tidiv bx\n\tmov " + temp_asm_var + ", ax\n";
			}
			else 
			{
				$$->code += "\tmov ax, " + $1->getSymbol() + "\n\tcwd\n";
				$$->code += "\tmov bx, " + $3->getSymbol();
				$$->code += "\tidiv bx\n\tmov " + temp_asm_var + ", dx\n";
			}

			$$->setSymbol(temp_asm_var);

		}


	}
     ;

unary_expression : ADDOP unary_expression {

		$$ = new SymbolInfo($1->getName() + $2->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unary_expression : ADDOP unary_expression\n\n", line_count);

		cout<<"in unary_expression: addop unary_expression"<<endl;


		if($2->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
            error_count++;
            $2->setSelfType("int");
		}

		$$->setSelfType($2->getSelfType());

		fprintf(log_file, "%s%s\n\n", $1->getName().c_str(), $2->getName().c_str() );


		if(error_count == 0)
		{
			if($1->getName() == "-")
			{
				string temp_asm_var = newTemp();
				data_segment.push_back(temp_asm_var + " dw ?");

				cout<<"temp var name: "<<temp_asm_var<<endl;
				

				cout<<"in getname - "<<endl;
				cout<<"data segment push: "<<endl;
				cout<<data_segment.back()<<endl;

				$$->code += $2->code;
				$$->code += "\tmov bx, " + $2->getSymbol() + "\n\tneg bx\n\tmov " + temp_asm_var + ", bx\n";
				$$->setSymbol(temp_asm_var);
			}
			else 
			{
				$$->code = $2->code;
				$$->setSymbol($2->getSymbol());
			}
		}

		


	}
		 | NOT unary_expression {

		$$ = new SymbolInfo("!" + (string)$2->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unary_expression : NOT unary_expression\n\n", line_count);


		if($2->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
            error_count++;
            $2->setSelfType("int");
		}

		$$->setSelfType("int");

		fprintf(log_file, "!%s\n\n", $2->getName().c_str() );


		if(error_count == 0)
		{
			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");

			string reset_label = newLabel();
			string exit_label = newLabel();

			$$->code = $2->code;
			$$->code += "\tmov ax, " + $2->getSymbol() + "\n\tcmp ax, 1\n";
			$$->code += "\tje " + reset_label + "\n\tmov " + temp_asm_var + ", 1\n\tjmp " + exit_label + "\n";
			$$->code += reset_label + ": \n\tmov " + temp_asm_var + ", 0\n" + exit_label + ": \n";

			$$->setSymbol(temp_asm_var); 
		}



	}
		 | factor {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: unary_expression : factor\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());

		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());

	}
		 ;

factor	: variable {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : variable\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());

		$$->setVarType($1->getVarType());
		$$->setVarSize($1->getVarSize());

		$$->code += $1->code;
		$$->setSymbol($1->getSymbol());

		if($1->getVarType() == "arr")
		{
			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");

			$$->code += "\t mov bx, " + $1->getSymbol() + "[si]\n\tmov " + temp_asm_var + ", bx\n";
			$$->setSymbol(temp_asm_var);
		}

	}
	| ID LPAREN argument_list RPAREN {

		$$ = new SymbolInfo($1->getName() + "(" + $3->getName() + ")", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : ID LPAREN argument_list RPAREN\n\n", line_count);


		bool valid = false;


		SymbolInfo *symbol = symboltable->lookup($1->getName());

		if(symbol == NULL){

			fprintf(log_file, "Error at line %d: Undeclared function %s\n\n", line_count, $1->getName().c_str());

			fprintf(error_file, "Error at line %d: Undeclared function %s\n\n", line_count, $1->getName().c_str());
                	error_count++;

               		$$->setSelfType("int");
		}
		else{

			if(symbol->getVarType() != "func_defn"){

				fprintf(log_file, "Error at line %d: No such function definition found\n\n", line_count);

				fprintf(error_file, "Error at line %d: No such function definition found\n\n", line_count);
               	 		error_count++;

                		$$->setSelfType("int");
			}
			else{
				if(symbol->getParamLen() == 1 && symbol->getParamAt(0).param_type == "void" && arg_list.size() == 0){
					
					valid = true;

					$$->setSelfType(symbol->getSelfType());
				}
				else if(symbol->getParamLen() != arg_list.size()){
					fprintf(log_file, "Error at line %d: Total number of arguments mismatch in function %s\n\n", line_count, $1->getName().c_str());

					fprintf(error_file, "Error at line %d: Total number of arguments mismatch in function %s\n\n", line_count, $1->getName().c_str());
                    			error_count++;

                    			$$->setSelfType("int");
				}
				else{
					int i;
					bool mismatch = false;


					for(i=0; i<arg_list.size(); i++){
						if(arg_list[i] != symbol->getParamAt(i).param_type){

							fprintf(log_file, "Error at line %d: %dth argument mismatch in function %s\n\n", line_count, i+1, $1->getName().c_str());
							fprintf(error_file, "Error at line %d: %dth argument mismatch in function %s\n\n", line_count, i+1, $1->getName().c_str());

                       					error_count++;

							mismatch = true;
							break;
						}
					}

					if(!mismatch){
						valid = true;
						$$->setSelfType(symbol->getSelfType());
					}
				}
			}

		}

		if(valid && error_count == 0)
		{
			string temp_asm_var = newTemp();
			data_segment.push_back(temp_asm_var + " dw ?");

			$$->code += $3->code;

			$$->code += "\tpush mem_add\n";

			for(int i = 0; i < send_arg_list.size(); i++)
			{
				$$->code += "\tpush " + send_arg_list[i] + "\n";
			}

			$$->code += "\tcall " + symbol->getSymbol() + "\n";

			if($$->getSelfType() != "void")
			{
				$$->code += "\tpop " + temp_asm_var + "\n";
			}
			
			$$->setSymbol(temp_asm_var);
			
			$$->code += "\tpop mem_add\n\t";
		}

		send_arg_list.clear();
		arg_list.clear();

		fprintf(log_file, "%s(%s)\n\n", $1->getName().c_str(), $3->getName().c_str() );


	}
	| LPAREN expression RPAREN {

		$$ = new SymbolInfo("(" + $2->getName() + ")", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : LPAREN expression RPAREN\n\n", line_count);

		if($2->getSelfType() == "void"){

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);


			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
               		error_count++;
               		$$->setSelfType("int");
		}

		$$->setSelfType($2->getSelfType());

		fprintf(log_file, "(%s)\n\n", $2->getName().c_str() );


		if(error_count == 0)
		{
			$$->code += $2->code;

			$$->setSymbol($2->getSymbol());

		}
		

	}
	| CONST_INT {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : CONST_INT\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType("int");

		$$->setSymbol($1->getName());


	}
	| CONST_FLOAT {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : CONST_FLOAT\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->setSelfType("float");

		$$->setSymbol($1->getName());


	}
	| variable INCOP {

		$$ = new SymbolInfo($1->getName() + "++", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : variable INCOP\n\n", line_count);

		fprintf(log_file, "%s++\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());


		string temp_asm_var = newTemp();
		data_segment.push_back(temp_asm_var + " dw ?");

		$$->code += $1->code;

		if($1->getVarType() == "var")
		{

			$$->code += "\tmov bx, " + $1->getSymbol() + "\n\tmov " + temp_asm_var + ", bx\n\tinc " + $1->getSymbol() + "\n";

		}
		else {


			$$->code += "\mov bx, " + $1->getSymbol() + "[si]\n\tmov " + temp_asm_var + ", bx\n\tinc " + $1->getSymbol() + "[si]\n";
			

		}

	}
	| variable DECOP {

		$$ = new SymbolInfo($1->getName() + "--", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: factor : variable DECOP\n\n", line_count);

		fprintf(log_file, "%s--\n\n", $1->getName().c_str() );

		$$->setSelfType($1->getSelfType());


		string temp_asm_var = newTemp();
		data_segment.push_back(temp_asm_var + " dw ?");

		$$->code += $1->code;

		if($1->getVarType() == "var")
		{
			
			$$->code += "\tmov bx, " + $1->getSymbol() + "\n\tmov " + temp_asm_var + ", bx\n\tdec " + $1->getSymbol() + "\n";

		}
		else {

			$$->code += "\tmov bx, " + $1->getSymbol() + "[si]\n\tmov " + temp_asm_var + ", bx\n\tdec " + $1->getSymbol() + "[si]\n";

		}

		$$->setSymbol(temp_asm_var);

	}
	;

argument_list : arguments {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: argument_list : arguments\n\n", line_count);

		fprintf(log_file, "%s\n\n", $1->getName().c_str() );

		$$->code += $1->code;

	}

	| {
		$$ = new SymbolInfo("", "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: argument_list : empty production\n\n", line_count);

		//fprintf(log_file, "\n\n");

	 }

			  ;

arguments : arguments COMMA logic_expression {

		$$ = new SymbolInfo($1->getName() + "," + $3->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: arguments : arguments COMMA logic_expression\n\n", line_count);


		if($3->getSelfType() == "void") {

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
	        error_count++;
			$3->setSelfType("int");
        	}

        	arg_list.push_back($3->getSelfType());

        	fprintf(log_file, "%s,%s\n\n", $1->getName().c_str(), $3->getName().c_str() );


			if(error_count == 0)
			{
				$$->code += $1->code + $3->code;
				send_arg_list.push_back($3->getSymbol());
			}



	}
	      | logic_expression {

		$$ = new SymbolInfo($1->getName(), "PRODUCTION_RULE");
		fprintf(log_file, "Line %d: arguments : logic_expression\n\n", line_count);


		if($1->getSelfType() == "void") {

			fprintf(log_file, "Error at line %d: Void function used in expression\n\n", line_count);

			fprintf(error_file, "Error at line %d: Void function used in expression\n\n", line_count);
	        error_count++;
			$1->setSelfType("int");
        	}

        	arg_list.push_back($1->getSelfType());

        	fprintf(log_file, "%s\n\n", $1->getName().c_str() );


			if(error_count == 0)
			{
				$$->code += $1->code;
				send_arg_list.push_back($1->getSymbol());
			}


	}
	      ;


%%
int main(int argc,char *argv[])
{

	/*
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}



	fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);

	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");
	*/

	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

	in_file = fin;

	log_file = fopen("1705018_log.txt","w");
	error_file = fopen("1705018_error.txt","w");
	code_file = fopen("code.asm","w");
	optimized_file = fopen("optimized_code.asm","w");

	symboltable = new SymbolTable(30);



	yyin=in_file;
	yyparse();

	fprintf(log_file, "\n");

	symboltable->print_all(log_file);
	symboltable->exitScope();

	fprintf(log_file, "Total lines: %d\n", line_count);
	fprintf(log_file, "Total errors: %d\n", error_count);
	fprintf(error_file, "Total errors: %d\n", error_count);

	cout<<"total errors: "<<error_count<<endl;
	cout<<"total lines: "<<line_count<<endl;



	fclose(in_file);
	fclose(log_file);
	fclose(error_file);


	return 0;
}

