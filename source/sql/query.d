module sql.query;
import sql.grammar;
import sql.parser;
import sql.attributes;
import std.typecons : Tuple;
import std.format : format;
import std.uni : sicmp;
import std.array : join;
import std.algorithm.searching : countUntil, count;

template SQLQuery(DB, string query)
{
    //To cache construction of query objects.
    //mixin(Cache!("queries", makeQuery, DB, query);
    enum code = makeQuery!(DB)(query);
    //pragma(msg, code);
    mixin(code);
    alias SQLQuery = Query;
}

template SQLUpdate(DB, string query)
{
	enum code = makeUpdate!(DB)(query);	
	mixin(code);
	alias SQLUpdate = Update;
}

template Pack(T...)
{
	alias Unpack = T;
}

template SQLInsertOrUpdate(Table, members...)
{
	enum code = makeInsert!(Table, members)("insert ignore");
	mixin(code);

	alias SQLInsertOrUpdate = Input;
}

template SQLInsert(T...)
{
	enum code = makeInsert!(Pack!(T))("insert");
	mixin(code);

	alias SQLInsert = Insert;
}


auto update(SQLUpdate, Con)(SQLUpdate update, ref Con con)
{
	con.execute(update.sql_, update.tupleof);
}

auto insert(SQLInsert, Con)(SQLInsert insert, ref Con con)
{
	con.execute(insert.sql_, insert.tupleof);
}

auto query(SQLQuery, Con)(SQLQuery query, Con con)
{
	import mysql;
    alias Res = SQLQuery.Result;
    Res[] result;
    con.execute(query.sql_, query.tupleof, (MySQLRow row)
    {
        Res res;
        foreach(i, dummy; Res.init.tupleof)
        {
			enum name = __traits(identifier, Res.tupleof[i]);
			alias type = typeof(dummy);
            mixin("res." ~ name ~ " = row." ~ name ~ ".get!(" ~ type.stringof ~ ");");
        }
        result ~= res;
    });

    return result;
}

private auto makeInsert(Table, members...)(string kind)
{
	enum tableName = getTableName!(Table);

	string fields = "";
	foreach(mem; members)
	{
		auto t = Table.init;
		alias field = Alias!(__traits(getMember, t, mem));
		alias typ  = typeof(field[0]);
		static if(isInstanceOf!(Varchar, typ))
			alias type = string;
		else 
			alias type = typ;

		fields ~= "    " ~ type.stringof ~ " ";
		fields ~= mem ~ ";\n";
	}

	string sql()
	{
		string fields = "(";
		string values = "(";
		foreach(mem; members)
		{
			fields ~= mem ~ ",";
			values ~= "?,";
		}

		fields = fields[0 .. $ - 1] ~ ")";
		values = values[0 .. $ - 1] ~ ")";

		return "\"" ~ kind ~ " " ~ tableName ~ fields ~ " values " ~ values ~ "\"";
	}

	return format("
enum sql = %s;
struct Input
{
   __gshared sql_ = sql;
   %s;
}
", sql(), fields);
}

private auto makeUpdate(DB)(string query)
{
	auto ast = SQL.decimateTree(SQL.UpdateStmt(query));
	assert(ast.successful, "Invalid SQL syntax!");
	
	auto c = extractUpdateContext!(DB)(ast);
	auto sql = formatSQL(query);
	auto inputs = formatInputs(c);

	return format("
enum sql = %s;
struct Update
{
	__gshared sql_ = sql;
%s
}
"		,sql, inputs); 
}

private auto makeQuery(DB)(string query)
{
    auto ast = SQL(query);

    //This should be improved to get better error messages
    //But generating errors at compiletime does not work good
    //atm.
    assert(ast.successful, "Invalid SQL syntax!");

    auto c = extractSelectContext!(DB)(ast);
    auto sql = formatSQL(query);
    auto inputs  = formatInputs(c);
    auto results = formatResults(c);

    return format("
enum sql = %s;

struct Query
{
    __gshared sql_ = sql;
%s

	struct Result
	{
		%s
	}
}
"    , sql, inputs, results);
}

private auto formatSQL(string query)
{
    string s = "\"";
    size_t sIndex = 0;
    foreach(i, char c; query)
    {
        if(c == '{')
            s ~= query[sIndex .. i] ~ "?";
        else if(c == '}')
            sIndex = i + 1;
    }
    s ~= query[sIndex .. $];
    return s ~ "\"";
}

private string formatInputs(C)(C c)
{
    string s = "";
    foreach(i; c.inputs) {
        s ~= "    " ~ i.type ~ " " ~ i.id ~ ";\n";
    }
    return s;
}

private string formatResults(C)(C c)
{
    string s = "";
    foreach(i, sel; c.selected)
    {
        auto col = c.columns[sel.column];
        s ~= "    " ~ col.type ~ " " ~ col.id ~ ";\n";
    }
    return s;
}

private struct UpdateContext
{
	TableID[] tables;
	ColumnID[] columns;
	Input[] inputs;
}

private struct SelectContext
{
    TableID[]  tables;
    ColumnID[] columns;
    SelectedColumn[] selected;
    Input[] inputs;
}

private struct Input
{
    string type;
    string id;
}

private struct SelectedColumn
{
    size_t column;
}

private struct ColumnID
{
    size_t table;
    string type;
    string id;
}

private struct TableID
{
    string alias_;
    string id;
}

private SelectContext extractSelectContext(DB)(ParseTree ast)
{
    SelectContext c;
    extractTables!(DB)(ast, c);
    extractSelected(ast, c);
    extractInputs(ast, c);
    return c;
}

private UpdateContext extractUpdateContext(DB)(ParseTree ast)
{
	UpdateContext c;
	extractTables!(DB)(ast, c);
	extractSet(ast, c);
	return c;
}

private void extractTables(DB, C)(ParseTree ast, ref C c)
{
    findAll("SQL.TableExpr", ast, (ParseTree tree)
    {
        TableID id;
        id.id = tree.matches[0];
        if(tree.children.length == 2) {
            id.alias_ = tree.matches[1];
        } else {
            id.alias_ = id.id;
        }
        c.tables ~= id;
    });

    foreach(Table; getTables!DB)
    {
        enum tableName = getTableName!(Table);
        foreach(i, table; c.tables)
        {
            if(sicmp(tableName, table.id) == 0)
                extractColumns!(Table)(i, c);
        }
    }
}

private void extractColumns(Table, C)(int idx, ref C c)
{
    foreach(i, dummy; Table.init.tupleof)
    {
        alias field  = Alias!(Table.tupleof[i]);
        alias type   = typeof(dummy);
		enum colName = getColumnName!(field);
		static if(isInstanceOf!(Varchar, type)) 
			enum typeID = string.stringof;
		else 
			enum typeID = type.stringof;

        c.columns ~= ColumnID(idx, typeID, colName);
    }
}

private size_t fieldColumn(C)(ParseTree field, ref C c)
{
    if(field.matches.length == 2)
    {
        auto tid = field.matches[0];
        auto cid = field.matches[1];
        auto tIdx = c.tables.countUntil!(x => x.alias_ == tid);
        assert(tIdx != -1, format("Table %s is not present in DB", tid));

        auto cIdx = c.columns.countUntil!(x => x.id == cid && x.table == tIdx);
        assert(cIdx != -1, format("Column %s not present in table %s",
                                  cid, tid));
        return cIdx;
    }
    else
    {
        auto cid  = field.matches[0];
        auto matches = c.columns.count!(x => x.id == cid);
        if(matches == 0)
            assert(0, format("Unrecognised column %s", cid));
        else if(matches > 1)
            assert(0, format("Column %s matches multiple tables",
                              cid));
        return c.columns.countUntil!(x => x.id == cid);
    }
}

private void extractSelected(ParseTree ast, ref SelectContext c)
{
    auto list = findFirst(ast, "SQL.ColumnListExpr");
    foreach(colNodeExp; list.children)
    {

        //Gotta skip columnExpr and get down to the inner node
        auto colExp = colNodeExp.children[0];
		if(colExp.name == "Select.ColumnExpr")
			colExp = colExp.children[0];

        switch(colExp.name)
        {
            case "SQL.AllExpr":
                foreach(i, col; c.columns)
                    c.selected ~= SelectedColumn(i);
                break;
            case "SQL.FullTableExpr":
                auto tid  = colExp.matches[0];
                auto tIdx =  c.tables.countUntil!(x => x.alias_ == tid);
                assert(tIdx != -1, format("Table %s is not present in DB", tid));
                foreach(i, col; c.columns) if(col.table == tIdx)
                    c.selected ~= SelectedColumn(i);
                break;
            case "SQL.FieldExpr":
                c.selected ~= SelectedColumn(fieldColumn(colExp, c));
                break;
            default:
                assert(0, "Invalid parse tree " ~ colExp.name ~ " " ~ colNodeExp.name);
        }
    }
}

private void extractInputs(ParseTree ast, ref SelectContext c)
{
    findAll("SQL.BinaryCondExpr", ast, (ParseTree tree)
    {
        auto left  = tree.children[0].children[0];
        auto right = tree.children[2].children[0];

        Input i;
        if(left.name == "SQL.InputExpr")
        {
            assert(right.name == "SQL.FieldExpr", "SQL makes no sence");
            i.id = left.matches[0];
            i.type = c.columns[fieldColumn(right, c)].type;
            c.inputs ~= i;
        }
        else if(right.name == "SQL.InputExpr")
        {
            assert(left.name == "SQL.FieldExpr", "SQL makes no sence");
            i.id = right.matches[0];
            i.type = c.columns[fieldColumn(left, c)].type;
            c.inputs ~= i;
        }
    });
}

private void extractSet(ParseTree ast, ref UpdateContext c)
{
	findAll("SQL.SetExpr", ast,  (t)
	{
	   auto field  = t.children[0];	
	   auto value  = t.children[1];
	   auto column = c.columns[fieldColumn(field, c)];
	   
	   assert(field.name == "SQL.FieldExpr");
	   assert(value.name == "SQL.InputExpr");
		
	   c.inputs ~= Input(column.type, value.matches[0]);
	});

	findAll("SQL.BinaryCondExpr", ast, (ParseTree tree)
    {
        auto left  = tree.children[0].children[0];
        auto right = tree.children[2].children[0];

        Input i;
        if(left.name == "SQL.InputExpr")
        {
            assert(right.name == "SQL.FieldExpr", "SQL makes no sence");
            i.id = left.matches[0];
            i.type = c.columns[fieldColumn(right, c)].type;
            c.inputs ~= i;
        }
        else if(right.name == "SQL.InputExpr")
        {
            assert(left.name == "SQL.FieldExpr", "SQL makes no sence");
            i.id = right.matches[0];
            i.type = c.columns[fieldColumn(left, c)].type;
            c.inputs ~= i;
        }
    });
}