module sql.attributes;
public import std.traits;
public import std.meta;

//AliasSeq is such a bad name.
//I do much prefer Alias
//In addition the current Alias in
//std.meta is wierd, what would be the usecase?
alias Alias(T...) = T;

//When placed on a struct it signifies that the struct
//contains a description of a database.
//Unlike Table and Column attributes this attribute
//MUST be present on a database descriptor.
struct Database
{
    //Name of the database
    string name;
}

///When placed on a struct it signifies that the struct
///has a diffrent name than the struct name.
///
///Example:
///@Table("My Users")
///struct Users
///{
///   @Primary
///   int id;
///   ...
///}
///Note this attribute is only needed for complex table names
///e.g  When the table name cannot be written as a standard
///     D structure identifier
///BUT for documentation it could be usefull to add it anyways.
struct Table
{
     //Name of the table
     string name;
}

///When placed on a field in a struct it signifies that the struct
///has a name that differs from the field name.
///
///Example:
///struct Users
///{
///   @Column("User Ids")
///   int id;
///   ...
///}
///Note this attribute is only needed for complex column names
///e.g  When the column name cannot be written as a standard
///     D structure identifier.
///BUT for documentation it could be usefull to add it anyways.
struct Column
{
    //Name of the column
    string name;
}

///When placed on a field in a struct it signifies that the field
///references a key in another table.
///SEE template Foreign for usage.
struct Foreign()
{
    string table;
    string field;
}

///Helper template allowing the following syntax for foreign keys
///
///struct Users
///{
///   @Primary
///   int id;
///   ...
///}
///struct Products
///{
///   @Primary
///   int id;
///   string description;
///   ...
///}
///struct Purchased
///{
///    //This column references the Users.id column.
///    @Foreign!(Users.id)
///    int user;
///
///    //This column references the Users.id column.
///    @Foreign!(Products.id)
///    int product;
///
///    DateTime timeOfPurchase;
///}
///In the example the table Purchased references Users.id and Products.id
template Foreign(alias OtherKey)
{
    alias parent  = Alias!(__traits(parent, OtherKey));
    enum table    = __traits(identifier, parent);
    enum field    = __traits(identifier, OtherKey);
    enum Foreign = .Foreign!()(table, field);
}

///When placed on a field in a struct it represents that this column
///is part of the primary key of the table.
///Example:
///struct User
///{
///    //This makes id the primary key for the User table
///    @Primary
///    int id;
///}
///
///struct UsingProducts
///{
///    //This column is part of the primary key.
///    @Primary
///    int user;
///
///    //So is this column.
///    @Primary
///    int product;
///}
enum Primary;

///When placed on a field in a struct it represents that each value
///in this column has to be unique.
enum Unique;

///When placed in a field in a struct it represents that values in this
///column cannot be null.
enum NotNull;


///When placed on a field in a struct it representat that the column will
///automatically get incremented when new rows are inserted.
enum AutoIncrement;

//Represents the type VARCHAR in sql
//Adds length information of variable fields
//to strings.
struct Varchar(size_t N)
{
    const(char)[] value;
    alias value this;
}


//Helper template to see if a symbol has a value UDA.
template hasValueUDA(Items...) if(Items.length == 2)
{
    alias T   = Items[0];
    alias UDA = Items[1];

    alias UDAs = getUDAs!(T, UDA);
    static if(__traits(compiles, (() {
        auto x = UDAs[0];
        })()))
    {
        //pragma(msg, "Has value: ", T);
        enum hasValueUDA = true;
    }
    else
    {
        //pragma(msg, "Does not have value: ", T);
        enum hasValueUDA = false;
    }
}


alias isNamedTable(alias T)  = hasValueUDA!(T, Table);
alias isNamedColumn(alias T) = hasValueUDA!(T, Column);

template getTables(T)
{
    enum members = [__traits(allMembers, T)];
    template helper(size_t idx)
    {
        static if(idx == members.length) {
            alias helper = Alias!();
        } else {
            alias mem = Alias!(__traits(getMember, T, members[idx]));
            static if(is(mem[0] == struct)) {
                alias helper = Alias!(mem, helper!(idx + 1));
            } else {
                alias helper = helper!(idx + 1);
            }
        }
    }

    alias getTables = helper!(0);
}

template getTableName(alias T)
{
    static if(isNamedTable!(T))
        enum getTableName = getUDAs!(T, Table)[0].name;
    else
        enum getTableName = T.stringof;
}

template getColumnName(alias T)
{
    static if(isNamedColumn!(T))
        enum getColumnName = getUDAs!(T, Column)[0].name;
    else
        enum getColumnName = T.stringof;
}
