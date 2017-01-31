module sql.query;
import sql.parser;
import sql.grammar;
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
    //pragma(msg, SQL(query).toString);
    enum code = makeQuery!(DB)(query);
    mixin(code);
    alias SQLQuery = Query;
}

private auto makeQuery(DB)(string query)
{
    auto ast = SQL(query);

    //This should be improved to get better error messages
    //But generating errors at compiletime does not work good
    //atm.
    assert(ast.successful, "Invalid SQL syntax!");

    auto c = extractContext!(DB)(ast);
    auto sql = formatSQL(query);
    auto inputs  = formatInputs(c);
    auto results = formatResults(c);

    return format("
enum sql = %s;

struct Query
{
    __gshared sql_ = sql;
%s
    alias Result = Tuple!(%s);
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

private string formatInputs(Context c)
{
    string s = "";
    foreach(i; c.inputs) {
        s ~= "    " ~ i.type ~ " " ~ i.id ~ ";\n";
    }
    return s;
}

private string formatResults(Context c)
{
    string s = "";
    foreach(i, sel; c.selected)
    {
        auto col = c.columns[sel.column];
        s ~= col.type ~ ", \"" ~ col.id ~ "\"";
        if(i != c.selected.length - 1)
            s ~= ", ";
    }
    return s;
}

private struct Context
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

private Context extractContext(DB)(ParseTree ast)
{
    Context c;
    extractTables!(DB)(ast, c);
    extractSelected(ast, c);
    extractInputs(ast, c);
    return c;
}

private void extractTables(DB)(ParseTree ast, ref Context c)
{
    findAll("SQL.TableExpr", ast, (ParseTree tree)
    {
        TableID id;
        id.id = tree.matches[0];
        if(tree.children.length == 1) {
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

private void extractColumns(Table)(int idx, ref Context c)
{
    foreach(i, dummy; Table.init.tupleof)
    {
        alias field  = Alias!(Table.tupleof[i]);
        enum colName = getColumnName!(field);
        enum type    = typeof(field[0]).stringof;
        c.columns ~= ColumnID(idx, type, colName);
    }
}

private size_t fieldColumn(ParseTree field, ref Context c)
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

private void extractSelected(ParseTree ast, ref Context c)
{
    auto list = findFirst(ast, "SQL.ColumnListExpr");
    foreach(colNodeExp; list.children)
    {

        //Gotta skip columnExpr and get down to the inner node
        auto colExp = colNodeExp.children[0];
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

private void extractInputs(ParseTree ast, ref Context c)
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
