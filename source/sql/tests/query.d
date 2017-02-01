module sql.tests.query;
version(unittest):
version(run_queries)
{

import sql.tests.database;
import sql.query;

alias GetUserFeedItems = SQLQuery!(RSSDatabase, q{
    select title, description, url
    from subs join items
    on subs.user = {user} and subs.feed = items.feed
    where subs.feed = {feed}
});

alias GetFeed = SQLQuery!(RSSDatabase, q{
    select * from items as t
    where t.feed = {id} and t.title = {hello}
});

auto query = GetUserFeedItems();


unittest
{
    template testSQL(string s)
    {
        import sql.parser;
        enum pt = SQL(s);
        static assert(pt.successful, "Failed to parse sql!\n" ~ s);
        //pragma(msg, s);
        void testSQL() { }
    }

    template testQuery(string s)
    {
        import sql.parser;
        //pragma(msg, s);
        alias A = SQLQuery!(RSSDatabase, s);
        void testQuery() { }
    }


    testQuery!(q{
        select url, title, description
        from feeds as f join users as u
        on u.id = f.user
        where u.id = {user}
    });

    testQuery!(q{
        select * from users;
    });

    testQuery!(q{
        select * from users order by users.id
    });

    testQuery!(q{
        select id, googleID from users
    });

    testQuery!(q{
        select id, googleID from users
        where id = {id}
    });

    testSQL!("SELECT * FROM TEST");
    testSQL!("SELECT * FROM TEST ORDER BY NAME");
    testSQL!("SELECT name, price FROM products");

    testSQL!("SELECT name, price FROM products WHERE price = 1.0");
    testSQL!("SELECT name, price FROM products WHERE name LIKE 'PEN'");
    testSQL!("SELECT name, price FROM products WHERE price = 1.0 AND p = 0 AND p = 1");
    testSQL!("SELECT name, quantity FROM products WHERE quantity <= 2000");
    testSQL!("SELECT name, price FROM products WHERE productCode = 'PEN'");
    testSQL!("SELECT * FROM products WHERE quantity >= 5000 AND price < 1.24 AND name LIKE 'Pen %'");
    testSQL!("SELECT * FROM products WHERE NOT (quantity >= 5000 AND name LIKE 'Pen %')");
    testSQL!("SELECT * FROM products WHERE name IN ('Pen Red', 'Pen Black')");
    testSQL!("SELECT * FROM products
                    WHERE (price BETWEEN 1.0 AND 2.0) AND (quantity BETWEEN 1000 AND 2000)");
    testSQL!("SELECT * FROM products WHERE productCode IS NULL");
    testSQL!("SELECT * FROM products WHERE productCode IS NOT NULL");
    testSQL!("SELECT * FROM products WHERE name LIKE 'Pen %' ORDER BY price DESC");
    testSQL!("SELECT * FROM products WHERE name LIKE 'Pen %' ORDER BY price DESC, quantity");
    testSQL!("SELECT * FROM products ORDER BY RAND()");
    testSQL!("SELECT * FROM products ORDER BY price LIMIT 2");
    testSQL!("SELECT * FROM products ORDER BY price LIMIT 2, 1");
    testSQL!("SELECT DISTINCT price, name FROM products");
    testSQL!("SELECT * FROM products GROUP BY productCode");
    testSQL!("SELECT productCode, COUNT(*) FROM products GROUP BY productCode");
        testSQL!("SELECT MAX(price), MIN(price), AVG(price), STD(price), SUM(quantity)
                     FROM products");


    /+As column expressions
    testSQL!("SELECT productID AS ID, productCode AS Code,
              name AS Description, price AS `Unit Price`
              FROM products
              ORDER BY ID");
    testSQL!("SELECT CONCAT(productCode, ' - ', name) AS `Product Description`,
            price FROM products");
    testSQL!("SELECT productCode, COUNT(*) AS count
                    FROM products
                    GROUP BY productCode
                    ORDER BY count DESC");
    +/

}

}
