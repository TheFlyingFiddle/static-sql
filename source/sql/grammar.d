module sql.grammar;
import pegged.peg : ParseTree;
import pegged.grammar;

enum gram = q{
SQL:
    SelectStmt      < ("select"i "distinct"i?
                                 ColumnListExpr
                                 FromStmt
                                 WhereStmt?
                                 GroupByStmt?
                                 HavingStmt?
                                 OrderByStmt?
                                 LimitStmt?)

    FromStmt        < "from"i TableExpr (JoinStmt Spacing)*
    WhereStmt       < "where"i Condition
    GroupByStmt     < "group"i "by"i FieldExpr (',' FieldExpr)*
    HavingStmt      < "having"i ConditionExpr

    OrderByStmt     < "order"i "by"i (FieldExpr ("desc"i / "asc"i)?) (:"," FieldExpr ("desc"i / "asc"i)?)*
    LimitStmt       < "limit"i [0-9]+ (:',' [0-9]+)?

    JoinStmt        < JoinKind? "join"i TableExpr OnStmt?
    JoinKind        < "inner"i / "outer"i / "left"i / "right"i
    OnStmt          < "on"i Condition
    Condition       <  NotExpr / InExpr / IsExpr / ConditionExpr
    NotExpr         < "not"i ConditionExpr
    InExpr          < FieldExpr "not"? "in"i '(' (Number / String) ',' (Number / String)')'
    IsExpr          < FieldExpr "is"i "not"i? "null"i

    ConditionExpr   < CondExpr (AndOrExpr)*
    AndOrExpr       < ("and"i / "or"i) CondExpr
    CondExpr        < '(' ConditionExpr ')' / BinaryCondExpr / TerneryCondExpr
    BinaryCondExpr  < CondIdent BinaryOp CondIdent
    TerneryCondExpr < CondIdent TerneryOp CondIdent "and"i CondIdent
    CondIdent       < Number / String / FieldExpr / InputExpr

    ColumnListExpr  < ColumnExpr (:',' ColumnExpr)*
    ColumnExpr      < (AllExpr / FuncExpr / FullTableExpr / FieldExpr)
    AllExpr         < '*'
    FullTableExpr   <  identifier :'.' '*'
    FieldExpr       <  identifier (:'.' identifier)?
    StringField     <~  :'`' (!'`' .)* :'`'
    TableExpr       <  identifier AsExpr?
    InputExpr       < :'{' identifier :'}'
    FuncExpr        < identifier '(' ColumnExpr (:"," ColumnExpr)* ')'
    AsExpr          < :"as"i identifier / StringField

    TerneryOp       < "between"i
    BinaryOp        < "<=" / ">=" / "=" / "<" / ">" / "like"i

    Number          <~ ('-'/'+')?  [0-9]+ ("." [0-9]+)?
    String          <~ (:quote (!quote .)* :quote)
    Spacing         <- :(blank)*
};

ParseTree findFirst(ParseTree pt, string name)
{
    ParseTree tree;
    bool helper(ParseTree child)
    {
        if(child.name == name)
        {
            tree = child;
            return true;
        }

        bool found = false;
        foreach(c; child.children)
        {
            if(helper(c)) {
                found = true;
                break;
            }
        }

        return found;
    }

    if(helper(pt))
        return tree;

    assert(0, "Was not found");
}

void findAll(string name, ParseTree tree, void delegate(ParseTree) cb)
{
    if(tree.name == name)
        cb(tree);

    foreach(child; tree.children)
        findAll(name, child, cb);
}

static this()
{
    asModule("sql.parser", "source/sql/parser", gram);
}

unittest
{
    template testSQL(string s)
    {
        import sql.parser;
        //pragma(msg, s);
        pragma(msg, SQL(s).matches);
        void testSQL() { }
    }


    testSQL!("select feed.url, feed.title, feed.description
              from feed
              join user
              on user.id = feed.user
              where user.id = {user}");

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
    testSQL!("SELECT productID AS ID, productCode AS Code,
                     name AS Description, price AS `Unit Price`
                     FROM products
                     ORDER BY ID");
    testSQL!("SELECT CONCAT(productCode, ' - ', name) AS `Product Description`, price FROM products");
    testSQL!("SELECT DISTINCT price, name FROM products");
    testSQL!("SELECT * FROM products GROUP BY productCode");
    testSQL!("SELECT productCode, COUNT(*) FROM products GROUP BY productCode");
    testSQL!("SELECT productCode, COUNT(*) AS count
                    FROM products
                    GROUP BY productCode
                    ORDER BY count DESC");
    testSQL!("SELECT MAX(price), MIN(price), AVG(price), STD(price), SUM(quantity)
                     FROM products");
    testSQL!("SELECT
                    productCode AS `Product Code`,
                    COUNT(*) AS Count
                    FROM products
                    GROUP BY productCode
                    HAVING Count >=3");
}
