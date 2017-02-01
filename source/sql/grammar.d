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
	UpdateStmt		< ("update"i TableExpr
								 SetListExpr
								 WhereStmt)

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

	SetListExpr		< "set"i SetExpr ("," SetExpr)*
	SetExpr         < FieldExpr :"=" InputExpr

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

unittest
{
    asModule("sql.parser", "source/sql/parser", gram);
}
