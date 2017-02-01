module sql.database;
import std.datetime : DateTime;
import sql.attributes;

private:

template FullyUnqual(T)
{
    static if(is(T == string))
        alias FullyUnqual = char[];
    else
        alias FullyUnqual = Unqual!(T);
}

//Converts a D type into equivalent type in SQL.
template getSqlType(U)
{
    alias T = FullyUnqual!U;
    static if(is(T == byte) || is(T == ubyte))
        enum getSqlType =  "TINYINT" ~ (isUnsigned!(T) ? " UNSIGNED" : "");
    else static if(is(T == short) || is(T == ushort))
        enum getSqlType = "SMALLINT" ~ (isUnsigned!(T) ? " UNSIGNED" : "");
    else static if(is(T == int) || is(T == uint))
        enum getSqlType =      "INT" ~ (isUnsigned!(T) ? " UNSIGNED" : "");
    else static if(is(T == long) || is(T == ulong))
        enum getSqlType =  "BIGINT" ~ (isUnsigned!(T) ? " UNSIGNED" : "");
    else static if(is(T == float))
        enum getSqlType = "FLOAT";
    else static if(is(T == double))
        enum getSqlType = "DOUBLE";
    else static if(is(T == real))
        enum getSqlType = "DOUBLE";
    else static if(is(T == DateTime))
        enum getSqlType = "DATETIME";
    else static if(is(T t == Varchar!(N), size_t N))
        enum getSqlType = "VARCHAR(" ~ N.stringof[0 .. $ - 1] ~ ")";
    else static if(is(T t == char[N], size_t N))
        enum getSqlType = "CHAR(" ~ N.stringof[0 .. $ - 1] ~ ")";
    else static if(is(T : char[]))
        enum getSqlType = "TEXT";
    else static if(is(T == ubyte[]) || is(T == void[]))
        enum getSqlType = "BLOB";
    else static assert(0, T.stringof ~ " " ~  U.stringof);
}

template test(F)
{
    static if(is(F f == Varchar!(N), size_t N))
    {
        pragma(msg, F.stringof, " ", N);
    }
    alias test = void;
}

alias F = test!(FullyUnqual!(Varchar!50));

//Possible Modifiers on columns.
string getModifiers(T, size_t index)()
{
    string s = "";
    static if(hasUDA!(T.tupleof[index], Unique))
        s ~= " UNIQUE";
    static if(hasUDA!(T.tupleof[index], NotNull))
        s ~= " NOT NULL";
    static if(hasUDA!(T.tupleof[index], AutoIncrement))
        s ~= " AUTO_INCREMENT";
    return s;
}

string createTableString(DB, Table)()
{
    enum tableName = getTableName!Table;
    string s = "CREATE TABLE IF NOT EXISTS " ~ tableName ~  "(";
    string pkeys;
    foreach(i, dummy; Table.init.tupleof)
    {
        alias field = Alias!(Table.tupleof[i]);
        alias type  = typeof(field[0]);
        s ~= getColumnName!(field) ~ " ";
        s ~= getSqlType!(type) ~ " ";
        s ~= getModifiers!(Table, i);
        s ~= ",";

        static if(hasUDA!(field, Primary))
            pkeys ~= getColumnName!(field) ~ ",";
    }

    if(pkeys.length == 0)
        //Remove trailing comma
        s = s[0 .. $ - 1];
    else
        s ~= "PRIMARY KEY (" ~ pkeys[0 .. $ - 1] ~ ")";

    s ~= ")";
    return s;
}

bool setupTable(DB, Table, Con)(Con con)
{
    __gshared makeTable = createTableString!(DB, Table);
    import std.stdio;
    //This is only a partial implementation as we don't
    //check to make sure things appear the way they should.
    //That is a more annoying problem tbh since we must reorder
    //fields, check to ensure that values are of the correct type
    //etc.
    //makeTableDiff

    try
    {
        con.execute(makeTable);
    }
    catch(Exception e)
    {
        writeln("Failed to run: ");
        writeln(makeTable);
    }

    //Depends on if we modified stuff.
    return false;
}

/++
+ Initializes the database described by the DB type.
+ Params:
+      con =    an opened database connection.
+/
public bool setupDatabase(DB, Con)(Con con) if(hasValueUDA!(DB, Database))
{
    enum dbName      = getUDAs!(DB, Database)[0].name;
    __gshared makeDB = "CREATE DATABASE IF NOT EXISTS " ~ dbName;

    con.execute(makeDB);
    con.use(dbName);

    bool partialMod = false;
    foreach(table; getTables!(DB))
        partialMod |= setupTable!(DB, table)(con);

    return partialMod;
}
