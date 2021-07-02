#include<bits/stdc++.h>
using namespace std;

//ofstream outfile;
//ifstream infile;


struct Parameter{

    string param_name, param_type;

};



class SymbolInfo{

private:
    string name, type;
    SymbolInfo *next;

    string symbol;



    string var_type = "";    // possible values: "var", "func_defn", "func_decl"  , "arr"
    string self_type = "";      // self type for var and array, return type for func
    int var_size = -1;

    vector<Parameter> param_list;



public:

    string code = "", optimized_code = "";


    SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->next = NULL;
    }

    ~SymbolInfo()
    {

    }

    void setNext(SymbolInfo* next_temp)
    {
        this->next = next_temp;
    }

    SymbolInfo* getNext()
    {
        return next;
    }

    void setName(string name)
    {
        this->name = name;

    }


    string getName(){
        return this->name;
    }

    void setType(string type)
    {
        this->type = type;

    }

    string getType()
    {
        return type;
    }



//============ offline 4 info ====================


    void setSymbol(string symbol)
    {
        this->symbol = symbol;
    }

    string getSymbol()
    {
        return this->symbol;
    }



//============ offline 3 info =====================


    void setVarType(string var_type)
    {
        this->var_type = var_type;
    }

    string getVarType()
    {
        return this->var_type;
    }

    void setSelfType(string self_type)
    {
        this->self_type = self_type;
    }

    string getSelfType()
    {
        return self_type;
    }

    void setVarSize(int var_size)
    {
        this->var_size = var_size;
    }

    int getVarSize()
    {
        return var_size;
    }

    int getParamLen()
    {
        return param_list.size();
    }

    void addParam(string param_name, string param_type)
    {

        Parameter temp;
        temp.param_name = param_name;
        temp.param_type = param_type;

        param_list.push_back(temp);

    }

    Parameter getParamAt(int idx)
    {
        return param_list[idx];
    }

};

class ScopeTable{

private:

    int total_buckets, id, current_child;
    SymbolInfo **symbols;

    ScopeTable *parent;

public:

    ScopeTable(int total_buckets, int id, ScopeTable *parent)
    {
        this->total_buckets = total_buckets;

        symbols = new SymbolInfo*[total_buckets];

        for(int i=0; i<total_buckets; i++)
            symbols[i] = NULL;

        this->id = id;
        this->current_child = 1;
        this->parent = parent;


        if(parent != NULL){
            cout<<"New ScopeTable with id "<<get_string_id()<<" created"<<endl;
            //outfile<<"New ScopeTable with id "<<get_string_id()<<" created"<<endl;

        }

    }

    ~ScopeTable()
    {
        cout<<"ScopeTable with id "<<get_string_id()<<" removed"<<endl;
        //outfile<<"ScopeTable with id "<<get_string_id()<<" removed"<<endl;

        for(int i=0; i<total_buckets; i++)
        {
            SymbolInfo *current = symbols[i], *temp = symbols[i];

            while(temp != NULL){

                current = current->getNext();
                delete temp;
                temp = current;
            }
        }

        delete[] symbols;
    }

    void setId(int id)
    {
        this->id = id;
    }

    int getId()
    {
        return id;
    }

    void setChildId()
    {
        current_child++;
    }

    int getChildId()
    {
        return current_child;
    }

    int getBuckets()
    {
        return total_buckets;
    }

    void setParent(ScopeTable *parent)
    {
        this->parent = parent;
    }

    ScopeTable* getParent()
    {
        return this->parent;
    }

    string get_string_id()
    {
        ScopeTable *temp2 = this;

        string id_str = "";

        while(temp2 != NULL)
        {
            id_str += to_string(temp2->getId());

            if(temp2->getParent() != NULL) {

                id_str += ".";

            }


            temp2 = temp2->getParent();
        }

        reverse(id_str.begin(), id_str.end());

        return id_str;

    }


    string get_string_id_asm()
    {
        ScopeTable *temp2 = this;

        string id_str = "";

        while(temp2 != NULL)
        {
            id_str += to_string(temp2->getId());

            if(temp2->getParent() != NULL) {

                id_str += "_";

            }


            temp2 = temp2->getParent();
        }

        reverse(id_str.begin(), id_str.end());

        return id_str;

    }







    int hashFunc(string symbol)
    {
        int sum = 0;
        for(int i=0; i<symbol.size(); i++)
        {
            sum += symbol[i];
        }

        sum %= total_buckets;

        return sum;
    }


    bool insert_symbol(string name, string type)
    {
        SymbolInfo *obj = new SymbolInfo(name, type);

        int hash_val = hashFunc(name), lvl = 0;

        if(symbols[hash_val] == NULL){
            symbols[hash_val] = obj;
        }
        else{
            SymbolInfo *temp = symbols[hash_val], *parent_symbol;

            while(temp != NULL){

                if(temp->getName() == name)
                {
                    cout<<"< "<<name<<", "<<type<<" > already exists in the current ScopeTable"<<endl;
                    //outfile<<"< "<<name<<", "<<type<<" > already exists in the current ScopeTable"<<endl;

                    return false;
                }
                parent_symbol = temp;
                temp = temp->getNext();
                lvl++;
            }

            if(parent_symbol != NULL)
                parent_symbol->setNext(obj);
        }

        cout<<"Inserted in ScopeTable# "<<get_string_id()<<" at position "<<hash_val<<", "<<lvl<<endl;
        //outfile<<"Inserted in ScopeTable# "<<get_string_id()<<" at position "<<hash_val<<", "<<lvl<<endl;


        return true;

    }

    bool insert_symbol_obj(SymbolInfo *symbol)
    {
        SymbolInfo *obj = lookup(symbol->getName());

        if(obj != NULL) return false;

        string name = symbol->getName(), type = symbol->getType();

        int hash_val = hashFunc(name), lvl = 0;

        if(symbols[hash_val] == NULL){
            symbols[hash_val] = symbol;
        }
        else{
            SymbolInfo *temp = symbols[hash_val], *parent_symbol;

            while(temp != NULL){

                if(temp->getName() == name)
                {
                    cout<<"< "<<name<<", "<<type<<" > already exists in the current ScopeTable"<<endl;
                    //outfile<<"< "<<name<<", "<<type<<" > already exists in the current ScopeTable"<<endl;

                    return false;
                }
                parent_symbol = temp;
                temp = temp->getNext();
                lvl++;
            }

            if(parent_symbol != NULL)
                parent_symbol->setNext(symbol);
        }

        cout<<"Inserted in ScopeTable# "<<get_string_id()<<" at position "<<hash_val<<", "<<lvl<<endl;
        //outfile<<"Inserted in ScopeTable# "<<get_string_id()<<" at position "<<hash_val<<", "<<lvl<<endl;


        return true;


    }


    SymbolInfo* lookup(string name)
    {
        int hash_val = hashFunc(name);

        SymbolInfo *temp = symbols[hash_val];

        while(temp != NULL)
        {
            if(temp->getName() == name){

                cout<<"Found in ScopeTable #"<<get_string_id()<<" at position "<<hashFunc(name)<<", "<<getSymbolPosition(name)<<endl;
                //outfile<<"Found in ScopeTable #"<<get_string_id()<<" at position "<<hashFunc(name)<<", "<<getSymbolPosition(name)<<endl;

                return temp;
            }
            temp = temp->getNext();
        }


        return NULL;
    }

    int getSymbolPosition(string name)
    {
        int hash_val = hashFunc(name), counter = 0;

        SymbolInfo *temp = symbols[hash_val];

        while(temp != NULL)
        {
            if(temp->getName() == name)
                return counter;

            counter++;
            temp = temp->getNext();

        }
    }

    bool delete_symbol(string name)
    {
        if(lookup(name)==NULL)
        {
            cout<<name<<" not found"<<endl;
            //outfile<<name<<" not found"<<endl;

            return false;
        }


        int hash_val = hashFunc(name), lvl = 0;

        SymbolInfo *temp = symbols[hash_val], *parent = NULL;

        while(temp != NULL)
        {
            if(temp->getName() == name){

                if(parent != NULL){
                    parent->setNext(temp->getNext());

                }
                else{
                    symbols[hash_val] = symbols[hash_val]->getNext();
                }

                cout<<"Deleted entry "<<hash_val<<", "<<lvl<<" from current ScopeTable"<<endl;
                //outfile<<"Deleted entry "<<hash_val<<", "<<lvl<<" from current ScopeTable"<<endl;

                delete temp;
                return true;

            }
            parent = temp;
            temp = temp->getNext();
            lvl++;
        }
    }

    void print_table(FILE *logout)
    {
        for(int i=0; i<total_buckets; i++){


            SymbolInfo *temp = symbols[i];


            if(temp == NULL) continue;

            cout<<i<<" --> ";
            fprintf(logout, " %d --> ", i);
            //outfile<<i<<" --> ";

            while(temp != NULL){
                cout<<"< "<<temp->getName()<<" , "<<temp->getType()<<" > ";
                fprintf(logout, "< %s , %s > ", temp->getName().c_str(), temp->getType().c_str());
                //outfile<<" < "<<temp->getName()<<" : "<<temp->getType()<<" >";

                temp = temp->getNext();
            }

            cout<<endl;
            fprintf(logout, "\n");
            //outfile<<endl;

        }
        fprintf(logout, "\n");

    }


};

class SymbolTable{

private:
    ScopeTable *scopes, *current_scope;
    int total_buckets;

public:

    SymbolTable(int total_buckets)
    {
        this->total_buckets = total_buckets;
        scopes = new ScopeTable(total_buckets, 1, NULL);
        current_scope = scopes;
    }

    ~SymbolTable()
    {
        ScopeTable *temp = current_scope;

        while(temp != NULL){
            current_scope = current_scope->getParent();
            delete temp;
            temp = current_scope;
        }

        delete scopes;
    }


    void enterScope()
    {
        ScopeTable *new_table;

        if(current_scope != NULL)
        {
            new_table = new ScopeTable(total_buckets, current_scope->getChildId(), current_scope);
            current_scope->setChildId();


        }
        else
            new_table = new ScopeTable(total_buckets, 1, current_scope);


        current_scope = new_table;


    }

    void exitScope()
    {
        //ScopeTable *temp = current_scope;
        current_scope = current_scope->getParent();
        //delete temp;
    }

    bool Insert(string name, string type)
    {
        return current_scope->insert_symbol(name, type);
    }

    bool InsertSymbolObj(SymbolInfo *symbol)
    {
        return current_scope->insert_symbol_obj(symbol);
    }


    bool Remove(string name)
    {
        return current_scope->delete_symbol(name);
    }


    string get_string_id_asm()
    {
        return current_scope->get_string_id_asm();
    }



    SymbolInfo* lookup(string name)
    {
        int level = 0;

        ScopeTable *temp = current_scope;
        SymbolInfo *symbol;

        while(temp != NULL)
        {
            symbol = temp->lookup(name);

            if(symbol != NULL)
            {
                return symbol;
            }

            temp = temp->getParent();
        }

        cout<<name<<" not found"<<endl;
        cout<<"NULL return kortesi"<<endl;

        return NULL;
    }

    SymbolInfo* lookup_current(string name)
    {
        int level = 0;

        ScopeTable *temp = current_scope;
        SymbolInfo *symbol;

        symbol = temp->lookup(name);

        return symbol;
    }

    void print_current(FILE *logout)
    {
        if(current_scope != NULL)
        {
            cout<<"ScopeTable #"<<current_scope->get_string_id()<<endl;
            fprintf(logout, "ScopeTable #%s", current_scope->get_string_id().c_str());
            //outfile<<"ScopeTable #"<<current_scope->get_string_id()<<endl;


            current_scope->print_table(logout);
        }

    }

    void print_all(FILE *logout)
    {
        ScopeTable *temp = current_scope;

        while(temp != NULL){

            cout<<"ScopeTable #"<<temp->get_string_id()<<endl;
            fprintf(logout, "ScopeTable # %s\n", temp->get_string_id().c_str());

            //outfile<<"ScopeTable #"<<temp->get_string_id()<<endl;

            temp->print_table(logout);
            temp = temp->getParent();

            cout<<endl;
            //outfile<<endl;
        }
    }

};



/*

int main()
{
    int total_buckets;
    string command, name, type;

    infile.open("input.txt");

    outfile.open("my_output.txt");

    infile>>total_buckets;

    SymbolTable *table = new SymbolTable(total_buckets);

    while(true)
    {
        infile>>command;

        if(command == "I"){

            infile>>name>>type;

            cout<<command<<" "<<name<<" "<<type<<endl;
            outfile<<command<<" "<<name<<" "<<type<<endl;

            table->Insert(name, type);

            command = "";

        }
        else if(command == "L")
        {
            infile>>name;

            cout<<command<<" "<<name<<endl;
            outfile<<command<<" "<<name<<endl;

            table->lookup(name);

            command = "";
        }
        else if(command == "D")
        {
            infile>>name;
            cout<<command<<" "<<name<<endl;
            outfile<<command<<" "<<name<<endl;


            table->Remove(name);
            command = "";
        }
        else if(command == "P")
        {
            infile>>type;
            cout<<command<<" "<<type<<endl;
            outfile<<command<<" "<<type<<endl;

            if(type == "A")
                table->print_all();
            else if(type == "C")
                table->print_current();

            command = "";
        }
        else if(command == "S")
        {
            cout<<command<<endl;
            outfile<<command<<endl;

            table->enterScope();
            command = "";
        }
        else if(command == "E")
        {
            cout<<command<<endl;
            outfile<<command<<endl;

            table->exitScope();
            command = "";
        }
        else{
            break;
        }
    }

    return 0;

}


*/















