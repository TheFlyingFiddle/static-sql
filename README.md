# static-sql
**static-sql** is a SQL code generarator and database interface library similar to SQL-LINQ written in the D programming language. 

The idea is to create a mysql database using annotated D structures along with a SQL DLS to provide queries on the created database. 

##Usage
```D
//First a database description has to be created.
//The following code creates a database called "my_database" 
//with 3 tables. users, products and purchases.
@Database("my_database")
struct MyDatabase
{
    struct Users
    {
        @Primary @AutoIncrement
        int id;

        Varchar!(100) name; 
        Varchar!(100) email;

        ///... more fields
    }
    
    struct Products
    {
        @Primary @AutoIncrement
        int id; 
        
        ubyte[] image; 
        string description;
  
        /// ... more columns price etc. 
    }
    
    struct Purchases
    {
        //user is a foreign key referencing Users.id
        @Foregin!(Users.id)
        int user;

        //product is a foreign key referencing Products.id
        @Foregin!(Products.id)
        int product; 
    }
}

//Using the database is done by creating query objects.
//These queries are typecheked at compile time. 
//Examples: 

//Gets the user table 
alias GetUsers = SQLQuery!(MyDatabase, q{
    select * from users; 
};

//Gets all purchased products from a specific user. 
//{ident} is an input for the query.
//In this case {id} will be of type int
alias GetPurchases = SQLQuery!(MyDatabase, q{
    select product from purchases 
    where id = {id}
});

void main()
{
    import mysql; //Uses mysql-lited as database driver
    auto connectString = //Your connection string. 
    auto client = new MySQLClient(connectionString);
    auto conn = client.lockConnection();

    //Creates tables and uses the database. 
    conn.setupDatabase!(MyDatabase);
    
    //Retrieves all users. 
    //users is an array of Users
    auto userQuery = GetUsers();
    auto users = userQuery.query(conn);

    //Gets all purchases for user with id=1
    //.id comes from the SQL query setup. 
    auto query = GetPurchases();
    query.id   = 1;
    
    //userOnePurchases is an array of structs having a field named "id"
    auto userOnePurchases = query.query(conn);
    writeln("User One: ", userOnePurchases);
    
    query.id    = 2;
    auto userTwoPurchases = query.query(conn);
    writeln("User Two: ", userTwoPurchases);
    
    //Queries can also be inlined if wanted. 
    auto itemQuery = SQLQuery!(MyDatabase, q{
        select distinct i.* from items as i
        join purchased as p 
        on i.id = p.item
        where p.user = {user}
    });
    
    itemQuery.user = 1; 
    
    //List of items user one has purchased. 
    auto userOneItems = itemQuery.query(conn);
}
```

##Limitations
Currently sub-queries and aggregate functions are not implemented. Additionaly queries can only be constructed at compiletime so no dynamic queries for now. If you want dynamic queries then this library is not for you. Direct usage of **mysql-lited** or similar is proboably a better fit in that case.






