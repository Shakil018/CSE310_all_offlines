%option noyywrap

%x CHAR_STATE
%x STRING_STATE
%x SINGLE_COMMENT_STATE
%x MULTI_COMMENT_STATE

%{
#include<iostream>
#include<algorithm>
#include<string>
#include"SymbolTable.cpp"
#define YYSTYPE SymbolInfo*
#include "y.tab.h"



using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *symboltable;;
void yyerror(char *);



extern int line_count;
extern int error_count;

int first_found = -1;


string store = "";

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE (\n)|(\r\n)

KEYWORDS "if"|"else"|"for"|"while"|"do"|"int"|"char"|"float"|"double"|"void"|"return"|"default"|"continue"|"println"|"main"


INTEGER {DIGIT}+
FLOAT {DIGIT}+(\.{DIGIT}*)?(E[+-]?{DIGIT}*)?

ADDOP "+"|"-"
MULOP (\*)|(\/)|(%)
INCOP "++"|"--"
RELOP (<)|(<=)|(>)|(>=)|(==)|(!=)
ASSIGNOP "="
LOGICOP "&&"|"||"
NOT "!"
LPAREN "("
RPAREN ")"
LCURL "{"
RCURL "}"
LTHIRD "["
RTHIRD "]"
COMMA ","
SEMICOLON ";"


ID ({LETTER}|_)+({LETTER}|{DIGIT}|_)*

INVALID_PREFIX_ID {DIGIT}+({LETTER}|_)({LETTER}|{DIGIT}|_)*

TOO_MANY_DECIMAL {DIGIT}*(\.{DIGIT}*)(\.{DIGIT}*)+{DIGIT}*
ILL_NUMBER_1 {DIGIT}*(\.{DIGIT}*)?(E[+-]?{DIGIT}*(\.)){DIGIT}*
ILL_NUMBER_2 {DIGIT}*(\.)(E[+-]?{DIGIT}*)?
ILL_NUMBER_3 {DIGIT}+(\.{DIGIT}*)(E[+-]?{DIGIT}*)?{LETTER}+


%%

{NEWLINE} {line_count++;}




\" {
		yymore();
		first_found  = line_count;
		BEGIN STRING_STATE;
	}
	
	
<STRING_STATE><<EOF>> {
		error_count++;
		//fprintf(logout,"Error at line no %d: Unterminated String %s\n\n", first_found, yytext);
		
		//symboltable->print_all(logout);
		
		//fprintf(logout,"Total lines: %d\n",line_count);
		//fprintf(logout,"Total errors: %d",error_count);
		return 0;

	}
	
<STRING_STATE>\\{NEWLINE} {
		line_count++;
		yymore();
	}
	
<STRING_STATE>[^"\n] {
		yymore();
	}
	
<STRING_STATE>\\\" {
		yymore();
	}
	
	
<STRING_STATE>(\") {


		char temp_char[strlen(yytext)];
		strcpy(temp_char, yytext);

		string temp(temp_char), actual = "";
		
		for(int i=0; i<temp.length(); i++)
		{
			if(temp[i] == '\\')
			{
				if(i+1 >= temp.length())
				{
					actual += temp[i];
					continue;
				}
				i++;
				if(temp[i] == '\r' && i+1 < temp.length() && temp[i+1] == '\n')
				{
					i++;
					continue;
				}
					
				if(temp[i] == '\n')
					continue;
				else if(temp[i] == 'n')
					actual += '\n';
				else if(temp[i] == 't')
					actual += '\t';
				else if(temp[i] == '\\')
					actual += '\\';
				else if(temp[i] == '\'')
					actual += '\'';
				else if(temp[i] == 'a')
					actual += '\a';
				else if(temp[i] == 'f')
					actual += '\f';
				else if(temp[i] == 'r')
					actual += '\r';
				else if(temp[i] == 'b')
					actual += '\b';
				else if(temp[i] == 'v')
					actual += '\v';
				else if(temp[i] == '0')
					actual += '\0';
				
				else if(temp[i] == '\"')
					actual += '\"';
				else 
				{
					i--;
					actual += temp[i];
				}
				
			}
			else
				actual += temp[i];
			
		}
		
		//fprintf(tokenout,"<STRING, %s> ", actual.c_str());
		//fprintf(logout,"Line no %d: Token <STRING> Lexeme %s found --> <STRING, %s> \n\n", first_found,yytext, actual.c_str());
		BEGIN INITIAL;
	} 
	
<STRING_STATE>\n {
		line_count++;
		error_count++;

		//fprintf(logout,"Error at line no %d: Unterminated String %s\n\n", first_found,yytext);
		
		BEGIN INITIAL;
		
	}
	
	
	

\' {
		yymore();
		first_found = line_count;
		BEGIN CHAR_STATE;
	}
	

<CHAR_STATE><<EOF>> {
		error_count++;
		//fprintf(logout,"Error at line no %d: Unterminated character %s\n\n", first_found, yytext);
		
		//symboltable->print_all(logout);
		
		//fprintf(logout,"Total lines: %d\n",line_count);
		//fprintf(logout,"Total errors: %d",error_count);
		
		return 0;


	}



<CHAR_STATE>(\\)(\')/(\') {
		yymore();
	}

<CHAR_STATE>\' {
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		char ch;

		string literal(temp);
		
		if(literal.length() == 2)
		{	
			error_count++;
			//fprintf(logout,"Error at line no %d: Empty character constant error %s\n\n", first_found, yytext);
			BEGIN INITIAL;
			break;

		}
		
		
		if(literal[1] == '\\')
		{
			if(literal.length()<4)
			{
				error_count++;
				//fprintf(logout,"Error at line no %d: Unterminated character %s\n\n", first_found, yytext);
				BEGIN INITIAL;
				break;
			}

			if(literal.length() >4)
			{
				error_count++;
				//fprintf(logout,"Error at line no %d: Multi character constant error %s\n\n", first_found, yytext);
				BEGIN INITIAL;
				break;
			}
			
			bool is_literal = true;

			if(literal[2] == 'n')
				ch = '\n';
			else if(literal[2] == 't')
				ch = '\t';
			else if(literal[2] == '\\')
				ch = '\\';
			else if(literal[2] == '\'')
				ch = '\'';
			else if(literal[2] == 'a')
				ch = '\a';
			else if(literal[2] == 'f')
				ch = '\f';
			else if(literal[2] == 'r')
				ch = '\r';
			else if(literal[2] == 'b')
				ch = '\b';
			else if(literal[2] == 'v')
				ch = '\v';
			else if(literal[2] == '0')
				ch = '\0';
			else
				is_literal = false;

			if(is_literal)
			{
	
				char temp2[strlen(yytext)];
				strcpy(temp2, yytext);
						
				string push(temp2);

				//fprintf(tokenout,"<CONST_CHAR, %c> ", ch);
				//fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR, %c>\n\n",first_found,yytext, ch);
			
				//bool inserted = symboltable->Insert(push, "CONST_CHAR");
				
				//if(inserted)
				//	symboltable->print_all(logout);
			

				
				BEGIN INITIAL;
			}
			else 
			{
				error_count++;	
				//fprintf(logout,"Error at line no %d: Unknown character %s found\n\n",first_found,yytext);
			}
			
		
		}
		else if(literal[2] == '\'')
		{
			char temp2[strlen(yytext)];
			strcpy(temp2, yytext);

			ch = literal[1];
						
			string push(temp2);

			

			//fprintf(tokenout,"<CONST_CHAR, %c> ", ch);
			//fprintf(logout,"Line no %d: Token <CONST_CHAR> Lexeme %s found --> <CONST_CHAR, %c> \n\n",first_found,yytext, ch);
			
			//bool inserted = symboltable->Insert(push, "CONST_CHAR");
			
			//if(inserted)
				//symboltable->print_all(logout);
			
			BEGIN INITIAL;


		}
		else
		{
			error_count++;
			//fprintf(logout,"Error at line no %d: Multi character constant error %s\n\n", first_found, yytext);
			BEGIN INITIAL;
		}

		
				
	}
	
	
<CHAR_STATE>[^\n] {
		yymore();
	}
	
<CHAR_STATE>\n {
		line_count++;
		error_count++;
		
		//fprintf(logout,"Error at line no %d: Unterminated character %s\n\n", first_found, yytext);
		BEGIN INITIAL;
	}


\/\/ {
		//yymore();
	
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
		
		
		first_found = line_count;
		store = comment;
		
		BEGIN SINGLE_COMMENT_STATE;
	
	}
	


	

<SINGLE_COMMENT_STATE>\\{NEWLINE} {
		//yymore();
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;
		
		line_count++;
		}


<SINGLE_COMMENT_STATE>{NEWLINE} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string comment(temp);
		
		//comment.pop_back();
		//comment.pop_back();
		
		
		line_count++;
		//fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s found \n\n", first_found, store.c_str());
		store = "";

		BEGIN INITIAL;
	}
	

<SINGLE_COMMENT_STATE>[^{NEWLINE}] {

		//yymore();
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;	
	}
	
<SINGLE_COMMENT_STATE><<EOF>> {

		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string comment(temp);
		
		//cout<<"never ending single line comment"<<endl;

		//fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s found \n\n", first_found, store.c_str());
		store = "";
		
		//symboltable->print_all(logout);
		
		//fprintf(logout,"Total lines: %d\n",line_count);
		//fprintf(logout,"Total errors: %d",error_count);


		return 0;
			
	}
	


<SINGLE_COMMENT_STATE>. {
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;
	
 		//yymore();
 		
 	}



\/\* {
	//yymore();
	
	char temp[strlen(yytext)];
	strcpy(temp, yytext);

	string comment(temp);
	
	store = comment;
	
	first_found = line_count;
	BEGIN MULTI_COMMENT_STATE;
	}
	
	


<MULTI_COMMENT_STATE>{NEWLINE} {
		
		//yymore();
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;
		
		
		line_count++;
	}



<MULTI_COMMENT_STATE>(\*)(\/) {


		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;

		//fprintf(logout,"Line no %d: Token <COMMENT> Lexeme %s found \n\n",first_found, store.c_str());
		store = "";
		BEGIN INITIAL;		
	}
	
<MULTI_COMMENT_STATE><<EOF>> {
		error_count++;

		//fprintf(logout,"Error at line no %d: Unterminated Comment %s\n\n",first_found,store.c_str());
		store = "";
		
		//symboltable->print_all(logout);
		
		//fprintf(logout,"Total lines: %d\n",line_count);
		//fprintf(logout,"Total errors: %d",error_count);
		
		return 0;
		
	}
	
	

<MULTI_COMMENT_STATE>[^\*\/] {
		
		//yymore();	
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;	
	}
	
<MULTI_COMMENT_STATE>. {
		//yymore();
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		
		string comment(temp);
	
		store += comment;
	}




"if" {return IF;}
"else" {return ELSE;}
"for" {return FOR;}
"while" {return WHILE;}
"int" {return INT;}
"float" {return FLOAT;}
"double" {return DOUBLE;}
"char" {return CHAR;}
"return" {return RETURN;}
"void" {return VOID;}
"println"|"printf"	{return PRINTLN;}




{INTEGER} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);
		
		
		SymbolInfo* symbolInfo = new  SymbolInfo(num, "CONST_INT");
    		yylval = (YYSTYPE) symbolInfo;

		
		return CONST_INT;		

		
		//fprintf(tokenout,"<CONST_INT, %s> ",yytext);
		//fprintf(logout,"Line no %d: Token <CONST_INT> Lexeme %s found \n\n",line_count,yytext);
		
		//bool inserted = symboltable->Insert(num, "CONST_INT");
		
		//if(inserted)
		//	symboltable->print_all(logout);
		

}

{FLOAT} {
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);
		
		
		SymbolInfo* symbolInfo = new  SymbolInfo(num, "CONST_FLOAT");
    		yylval = (YYSTYPE) symbolInfo;

		
		return CONST_FLOAT;		

		
		//fprintf(tokenout,"<CONST_FLOAT, %s> ",yytext);
		//fprintf(logout,"Line no %d: Token <CONST_FLOAT> Lexeme %s found\n\n",line_count,yytext);
		
		//bool inserted = symboltable->Insert(num, "CONST_FLOAT");
		
		//if(inserted)
		//	symboltable->print_all(logout);
		
		
	}



{TOO_MANY_DECIMAL} {
		error_count++;
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);
		
		SymbolInfo* symbolInfo = new  SymbolInfo(num, "CONST_FLOAT");
    		yylval = (YYSTYPE) symbolInfo;

		
		
		return CONST_FLOAT;
		//fprintf(logout,"Error at line no %d: Too many decimal points %s\n\n",line_count,yytext);
		
	}



{ILL_NUMBER_1}|{ILL_NUMBER_2}|{ILL_NUMBER_3} {
		error_count++;
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);

		string num(temp);
		
		SymbolInfo* symbolInfo = new  SymbolInfo(num, "CONST_FLOAT");
    		yylval = (YYSTYPE) symbolInfo;

		
		
		return CONST_FLOAT;
		//fprintf(logout,"Error at line no %d: Ill formed number %s\n\n",line_count,yytext);
		
	}


{ADDOP} { 
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string num(temp);

		SymbolInfo *s= new  SymbolInfo(num, "ADDOP");
		yylval = (YYSTYPE)s;
		return ADDOP;
	}



{MULOP}	{
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string num(temp);
		
		SymbolInfo *s= new  SymbolInfo(yytext, (char *)"MULOP");
		yylval = (YYSTYPE)s;
		return MULOP;
		}


"=" 	{return ASSIGNOP;}

">" |
"<" |
">=" |
"<=" |
"==" |
"!=" {

		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string num(temp);
		
		SymbolInfo *s= new  SymbolInfo(num, "RELOP");
		yylval = (YYSTYPE)s;
		return RELOP;
	}

"&&"	|
"||"	{
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string num(temp);
		
		SymbolInfo *s= new  SymbolInfo(num, "LOGICOP");
		yylval = (YYSTYPE)s;
		return LOGICOP;
	}

"!"		{	return NOT; }


";" 	{ return SEMICOLON;}
"," 	{return COMMA;}
"(" 	{return LPAREN;}
")" 	{return RPAREN;}
"{" 	{return LCURL;}
"}" 	{return RCURL;}
"[" 	{return LTHIRD;}
"]" 	{return RTHIRD;}
"++" 	{return INCOP;}
"--" 	{return DECOP;}














{ID} {

		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string id(temp);


		SymbolInfo *s= symboltable->lookup(temp);
		if(s==NULL)
		{					
			s= new SymbolInfo(temp, "ID");
		}
		yylval = (YYSTYPE)s;
						
		return ID;

		
	}


{INVALID_PREFIX_ID} {
		error_count++;
		
		char temp[strlen(yytext)];
		strcpy(temp, yytext);
		string num(temp);
		
		SymbolInfo *s= new  SymbolInfo(num, "ID");
		yylval = (YYSTYPE)s;
		
		return ID;
		
		//fprintf(logout,"Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",line_count,yytext);
	}
	
	
{WHITESPACE} {}

. {
		error_count++;
		//fprintf(logout,"Error at line no %d: Unrecognized character %s\n\n",line_count,yytext);
	}
	
	
<<EOF>> { 
		line_count--;
		//symboltable->print_all(logout);
		//fprintf(logout,"Total lines: %d\n",line_count);
		//fprintf(logout,"Total errors: %d",error_count);

		return 0;
	}

%%
