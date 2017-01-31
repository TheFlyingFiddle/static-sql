/++
This module was automatically generated from the following grammar:


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


+/
module sql.parser;

public import pegged.peg;
import std.algorithm: startsWith;
import std.functional: toDelegate;

struct GenericSQL(TParseTree)
{
	import std.functional : toDelegate;
    import pegged.dynamic.grammar;
	static import pegged.peg;
    struct SQL
    {
    enum name = "SQL";
    static ParseTree delegate(ParseTree)[string] before;
    static ParseTree delegate(ParseTree)[string] after;
    static ParseTree delegate(ParseTree)[string] rules;
    import std.typecons:Tuple, tuple;
    static TParseTree[Tuple!(string, size_t)] memo;
    static this()
    {
        rules["SelectStmt"] = toDelegate(&SelectStmt);
        rules["FromStmt"] = toDelegate(&FromStmt);
        rules["WhereStmt"] = toDelegate(&WhereStmt);
        rules["GroupByStmt"] = toDelegate(&GroupByStmt);
        rules["HavingStmt"] = toDelegate(&HavingStmt);
        rules["OrderByStmt"] = toDelegate(&OrderByStmt);
        rules["LimitStmt"] = toDelegate(&LimitStmt);
        rules["JoinStmt"] = toDelegate(&JoinStmt);
        rules["JoinKind"] = toDelegate(&JoinKind);
        rules["OnStmt"] = toDelegate(&OnStmt);
        rules["Condition"] = toDelegate(&Condition);
        rules["NotExpr"] = toDelegate(&NotExpr);
        rules["InExpr"] = toDelegate(&InExpr);
        rules["IsExpr"] = toDelegate(&IsExpr);
        rules["ConditionExpr"] = toDelegate(&ConditionExpr);
        rules["AndOrExpr"] = toDelegate(&AndOrExpr);
        rules["CondExpr"] = toDelegate(&CondExpr);
        rules["BinaryCondExpr"] = toDelegate(&BinaryCondExpr);
        rules["TerneryCondExpr"] = toDelegate(&TerneryCondExpr);
        rules["CondIdent"] = toDelegate(&CondIdent);
        rules["ColumnListExpr"] = toDelegate(&ColumnListExpr);
        rules["ColumnExpr"] = toDelegate(&ColumnExpr);
        rules["AllExpr"] = toDelegate(&AllExpr);
        rules["FullTableExpr"] = toDelegate(&FullTableExpr);
        rules["FieldExpr"] = toDelegate(&FieldExpr);
        rules["StringField"] = toDelegate(&StringField);
        rules["TableExpr"] = toDelegate(&TableExpr);
        rules["InputExpr"] = toDelegate(&InputExpr);
        rules["FuncExpr"] = toDelegate(&FuncExpr);
        rules["AsExpr"] = toDelegate(&AsExpr);
        rules["TerneryOp"] = toDelegate(&TerneryOp);
        rules["BinaryOp"] = toDelegate(&BinaryOp);
        rules["Number"] = toDelegate(&Number);
        rules["String"] = toDelegate(&String);
        rules["Spacing"] = toDelegate(&Spacing);
    }

    template hooked(alias r, string name)
    {
        static ParseTree hooked(ParseTree p)
        {
            ParseTree result;

            if (name in before)
            {
                result = before[name](p);
                if (result.successful)
                    return result;
            }

            result = r(p);
            if (result.successful || name !in after)
                return result;

            result = after[name](p);
            return result;
        }

        static ParseTree hooked(string input)
        {
            return hooked!(r, name)(ParseTree("",false,[],input));
        }
    }

    static void addRuleBefore(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar name
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(ruleName,rule; dg.rules)
            if (ruleName != "Spacing") // Keep the local Spacing rule, do not overwrite it
                rules[ruleName] = rule;
        before[parentRule] = rules[dg.startingRule];
    }

    static void addRuleAfter(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar named
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(name,rule; dg.rules)
        {
            if (name != "Spacing")
                rules[name] = rule;
        }
        after[parentRule] = rules[dg.startingRule];
    }

    static bool isRule(string s)
    {
		import std.algorithm : startsWith;
        return s.startsWith("SQL.");
    }
    mixin decimateTree;

    static TParseTree SelectStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("select"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("distinct"), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnListExpr, Spacing), pegged.peg.wrapAround!(Spacing, FromStmt, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WhereStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, GroupByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, HavingStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OrderByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, LimitStmt, Spacing))), Spacing), "SQL.SelectStmt")(p);
        }
        else
        {
            if (auto m = tuple(`SelectStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("select"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("distinct"), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnListExpr, Spacing), pegged.peg.wrapAround!(Spacing, FromStmt, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WhereStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, GroupByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, HavingStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OrderByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, LimitStmt, Spacing))), Spacing), "SQL.SelectStmt"), "SelectStmt")(p);
                memo[tuple(`SelectStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree SelectStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("select"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("distinct"), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnListExpr, Spacing), pegged.peg.wrapAround!(Spacing, FromStmt, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WhereStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, GroupByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, HavingStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OrderByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, LimitStmt, Spacing))), Spacing), "SQL.SelectStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("select"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("distinct"), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnListExpr, Spacing), pegged.peg.wrapAround!(Spacing, FromStmt, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WhereStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, GroupByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, HavingStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OrderByStmt, Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, LimitStmt, Spacing))), Spacing), "SQL.SelectStmt"), "SelectStmt")(TParseTree("", false,[], s));
        }
    }
    static string SelectStmt(GetName g)
    {
        return "SQL.SelectStmt";
    }

    static TParseTree FromStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("from"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, JoinStmt, Spacing), pegged.peg.wrapAround!(Spacing, Spacing, Spacing)), Spacing))), "SQL.FromStmt")(p);
        }
        else
        {
            if (auto m = tuple(`FromStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("from"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, JoinStmt, Spacing), pegged.peg.wrapAround!(Spacing, Spacing, Spacing)), Spacing))), "SQL.FromStmt"), "FromStmt")(p);
                memo[tuple(`FromStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree FromStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("from"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, JoinStmt, Spacing), pegged.peg.wrapAround!(Spacing, Spacing, Spacing)), Spacing))), "SQL.FromStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("from"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, JoinStmt, Spacing), pegged.peg.wrapAround!(Spacing, Spacing, Spacing)), Spacing))), "SQL.FromStmt"), "FromStmt")(TParseTree("", false,[], s));
        }
    }
    static string FromStmt(GetName g)
    {
        return "SQL.FromStmt";
    }

    static TParseTree WhereStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("where"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.WhereStmt")(p);
        }
        else
        {
            if (auto m = tuple(`WhereStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("where"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.WhereStmt"), "WhereStmt")(p);
                memo[tuple(`WhereStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree WhereStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("where"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.WhereStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("where"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.WhereStmt"), "WhereStmt")(TParseTree("", false,[], s));
        }
    }
    static string WhereStmt(GetName g)
    {
        return "SQL.WhereStmt";
    }

    static TParseTree GroupByStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("group"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing))), "SQL.GroupByStmt")(p);
        }
        else
        {
            if (auto m = tuple(`GroupByStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("group"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing))), "SQL.GroupByStmt"), "GroupByStmt")(p);
                memo[tuple(`GroupByStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree GroupByStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("group"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing))), "SQL.GroupByStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("group"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing))), "SQL.GroupByStmt"), "GroupByStmt")(TParseTree("", false,[], s));
        }
    }
    static string GroupByStmt(GetName g)
    {
        return "SQL.GroupByStmt";
    }

    static TParseTree HavingStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("having"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.HavingStmt")(p);
        }
        else
        {
            if (auto m = tuple(`HavingStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("having"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.HavingStmt"), "HavingStmt")(p);
                memo[tuple(`HavingStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree HavingStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("having"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.HavingStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("having"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.HavingStmt"), "HavingStmt")(TParseTree("", false,[], s));
        }
    }
    static string HavingStmt(GetName g)
    {
        return "SQL.HavingStmt";
    }

    static TParseTree OrderByStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("order"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing))), "SQL.OrderByStmt")(p);
        }
        else
        {
            if (auto m = tuple(`OrderByStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("order"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing))), "SQL.OrderByStmt"), "OrderByStmt")(p);
                memo[tuple(`OrderByStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree OrderByStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("order"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing))), "SQL.OrderByStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("order"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("by"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("desc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asc"), Spacing)), Spacing))), Spacing))), "SQL.OrderByStmt"), "OrderByStmt")(TParseTree("", false,[], s));
        }
    }
    static string OrderByStmt(GetName g)
    {
        return "SQL.OrderByStmt";
    }

    static TParseTree LimitStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("limit"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing))), Spacing))), "SQL.LimitStmt")(p);
        }
        else
        {
            if (auto m = tuple(`LimitStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("limit"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing))), Spacing))), "SQL.LimitStmt"), "LimitStmt")(p);
                memo[tuple(`LimitStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree LimitStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("limit"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing))), Spacing))), "SQL.LimitStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("limit"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing))), Spacing))), "SQL.LimitStmt"), "LimitStmt")(TParseTree("", false,[], s));
        }
    }
    static string LimitStmt(GetName g)
    {
        return "SQL.LimitStmt";
    }

    static TParseTree JoinStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, JoinKind, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("join"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OnStmt, Spacing))), "SQL.JoinStmt")(p);
        }
        else
        {
            if (auto m = tuple(`JoinStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, JoinKind, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("join"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OnStmt, Spacing))), "SQL.JoinStmt"), "JoinStmt")(p);
                memo[tuple(`JoinStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree JoinStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, JoinKind, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("join"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OnStmt, Spacing))), "SQL.JoinStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, JoinKind, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("join"), Spacing), pegged.peg.wrapAround!(Spacing, TableExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, OnStmt, Spacing))), "SQL.JoinStmt"), "JoinStmt")(TParseTree("", false,[], s));
        }
    }
    static string JoinStmt(GetName g)
    {
        return "SQL.JoinStmt";
    }

    static TParseTree JoinKind(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inner"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("outer"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("left"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("right"), Spacing)), "SQL.JoinKind")(p);
        }
        else
        {
            if (auto m = tuple(`JoinKind`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inner"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("outer"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("left"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("right"), Spacing)), "SQL.JoinKind"), "JoinKind")(p);
                memo[tuple(`JoinKind`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree JoinKind(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inner"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("outer"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("left"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("right"), Spacing)), "SQL.JoinKind")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inner"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("outer"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("left"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("right"), Spacing)), "SQL.JoinKind"), "JoinKind")(TParseTree("", false,[], s));
        }
    }
    static string JoinKind(GetName g)
    {
        return "SQL.JoinKind";
    }

    static TParseTree OnStmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.OnStmt")(p);
        }
        else
        {
            if (auto m = tuple(`OnStmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.OnStmt"), "OnStmt")(p);
                memo[tuple(`OnStmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree OnStmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.OnStmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "SQL.OnStmt"), "OnStmt")(TParseTree("", false,[], s));
        }
    }
    static string OnStmt(GetName g)
    {
        return "SQL.OnStmt";
    }

    static TParseTree Condition(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, NotExpr, Spacing), pegged.peg.wrapAround!(Spacing, InExpr, Spacing), pegged.peg.wrapAround!(Spacing, IsExpr, Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.Condition")(p);
        }
        else
        {
            if (auto m = tuple(`Condition`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, NotExpr, Spacing), pegged.peg.wrapAround!(Spacing, InExpr, Spacing), pegged.peg.wrapAround!(Spacing, IsExpr, Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.Condition"), "Condition")(p);
                memo[tuple(`Condition`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Condition(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, NotExpr, Spacing), pegged.peg.wrapAround!(Spacing, InExpr, Spacing), pegged.peg.wrapAround!(Spacing, IsExpr, Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.Condition")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, NotExpr, Spacing), pegged.peg.wrapAround!(Spacing, InExpr, Spacing), pegged.peg.wrapAround!(Spacing, IsExpr, Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.Condition"), "Condition")(TParseTree("", false,[], s));
        }
    }
    static string Condition(GetName g)
    {
        return "SQL.Condition";
    }

    static TParseTree NotExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.NotExpr")(p);
        }
        else
        {
            if (auto m = tuple(`NotExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.NotExpr"), "NotExpr")(p);
                memo[tuple(`NotExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree NotExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.NotExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing)), "SQL.NotExpr"), "NotExpr")(TParseTree("", false,[], s));
        }
    }
    static string NotExpr(GetName g)
    {
        return "SQL.NotExpr";
    }

    static TParseTree InExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("in"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.InExpr")(p);
        }
        else
        {
            if (auto m = tuple(`InExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("in"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.InExpr"), "InExpr")(p);
                memo[tuple(`InExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree InExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("in"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.InExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("in"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.InExpr"), "InExpr")(TParseTree("", false,[], s));
        }
    }
    static string InExpr(GetName g)
    {
        return "SQL.InExpr";
    }

    static TParseTree IsExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("is"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("null"), Spacing)), "SQL.IsExpr")(p);
        }
        else
        {
            if (auto m = tuple(`IsExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("is"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("null"), Spacing)), "SQL.IsExpr"), "IsExpr")(p);
                memo[tuple(`IsExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree IsExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("is"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("null"), Spacing)), "SQL.IsExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("is"), Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("not"), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("null"), Spacing)), "SQL.IsExpr"), "IsExpr")(TParseTree("", false,[], s));
        }
    }
    static string IsExpr(GetName g)
    {
        return "SQL.IsExpr";
    }

    static TParseTree ConditionExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.wrapAround!(Spacing, AndOrExpr, Spacing), Spacing))), "SQL.ConditionExpr")(p);
        }
        else
        {
            if (auto m = tuple(`ConditionExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.wrapAround!(Spacing, AndOrExpr, Spacing), Spacing))), "SQL.ConditionExpr"), "ConditionExpr")(p);
                memo[tuple(`ConditionExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree ConditionExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.wrapAround!(Spacing, AndOrExpr, Spacing), Spacing))), "SQL.ConditionExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.wrapAround!(Spacing, AndOrExpr, Spacing), Spacing))), "SQL.ConditionExpr"), "ConditionExpr")(TParseTree("", false,[], s));
        }
    }
    static string ConditionExpr(GetName g)
    {
        return "SQL.ConditionExpr";
    }

    static TParseTree AndOrExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, CondExpr, Spacing)), "SQL.AndOrExpr")(p);
        }
        else
        {
            if (auto m = tuple(`AndOrExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, CondExpr, Spacing)), "SQL.AndOrExpr"), "AndOrExpr")(p);
                memo[tuple(`AndOrExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree AndOrExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, CondExpr, Spacing)), "SQL.AndOrExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, CondExpr, Spacing)), "SQL.AndOrExpr"), "AndOrExpr")(TParseTree("", false,[], s));
        }
    }
    static string AndOrExpr(GetName g)
    {
        return "SQL.AndOrExpr";
    }

    static TParseTree CondExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), pegged.peg.wrapAround!(Spacing, BinaryCondExpr, Spacing), pegged.peg.wrapAround!(Spacing, TerneryCondExpr, Spacing)), "SQL.CondExpr")(p);
        }
        else
        {
            if (auto m = tuple(`CondExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), pegged.peg.wrapAround!(Spacing, BinaryCondExpr, Spacing), pegged.peg.wrapAround!(Spacing, TerneryCondExpr, Spacing)), "SQL.CondExpr"), "CondExpr")(p);
                memo[tuple(`CondExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree CondExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), pegged.peg.wrapAround!(Spacing, BinaryCondExpr, Spacing), pegged.peg.wrapAround!(Spacing, TerneryCondExpr, Spacing)), "SQL.CondExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ConditionExpr, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), pegged.peg.wrapAround!(Spacing, BinaryCondExpr, Spacing), pegged.peg.wrapAround!(Spacing, TerneryCondExpr, Spacing)), "SQL.CondExpr"), "CondExpr")(TParseTree("", false,[], s));
        }
    }
    static string CondExpr(GetName g)
    {
        return "SQL.CondExpr";
    }

    static TParseTree BinaryCondExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, BinaryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.BinaryCondExpr")(p);
        }
        else
        {
            if (auto m = tuple(`BinaryCondExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, BinaryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.BinaryCondExpr"), "BinaryCondExpr")(p);
                memo[tuple(`BinaryCondExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree BinaryCondExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, BinaryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.BinaryCondExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, BinaryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.BinaryCondExpr"), "BinaryCondExpr")(TParseTree("", false,[], s));
        }
    }
    static string BinaryCondExpr(GetName g)
    {
        return "SQL.BinaryCondExpr";
    }

    static TParseTree TerneryCondExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, TerneryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.TerneryCondExpr")(p);
        }
        else
        {
            if (auto m = tuple(`TerneryCondExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, TerneryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.TerneryCondExpr"), "TerneryCondExpr")(p);
                memo[tuple(`TerneryCondExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree TerneryCondExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, TerneryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.TerneryCondExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, TerneryOp, Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, CondIdent, Spacing)), "SQL.TerneryCondExpr"), "TerneryCondExpr")(TParseTree("", false,[], s));
        }
    }
    static string TerneryCondExpr(GetName g)
    {
        return "SQL.TerneryCondExpr";
    }

    static TParseTree CondIdent(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, InputExpr, Spacing)), "SQL.CondIdent")(p);
        }
        else
        {
            if (auto m = tuple(`CondIdent`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, InputExpr, Spacing)), "SQL.CondIdent"), "CondIdent")(p);
                memo[tuple(`CondIdent`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree CondIdent(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, InputExpr, Spacing)), "SQL.CondIdent")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing), pegged.peg.wrapAround!(Spacing, InputExpr, Spacing)), "SQL.CondIdent"), "CondIdent")(TParseTree("", false,[], s));
        }
    }
    static string CondIdent(GetName g)
    {
        return "SQL.CondIdent";
    }

    static TParseTree ColumnListExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing))), "SQL.ColumnListExpr")(p);
        }
        else
        {
            if (auto m = tuple(`ColumnListExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing))), "SQL.ColumnListExpr"), "ColumnListExpr")(p);
                memo[tuple(`ColumnListExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree ColumnListExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing))), "SQL.ColumnListExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing))), "SQL.ColumnListExpr"), "ColumnListExpr")(TParseTree("", false,[], s));
        }
    }
    static string ColumnListExpr(GetName g)
    {
        return "SQL.ColumnListExpr";
    }

    static TParseTree ColumnExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, AllExpr, Spacing), pegged.peg.wrapAround!(Spacing, FuncExpr, Spacing), pegged.peg.wrapAround!(Spacing, FullTableExpr, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing), "SQL.ColumnExpr")(p);
        }
        else
        {
            if (auto m = tuple(`ColumnExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, AllExpr, Spacing), pegged.peg.wrapAround!(Spacing, FuncExpr, Spacing), pegged.peg.wrapAround!(Spacing, FullTableExpr, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing), "SQL.ColumnExpr"), "ColumnExpr")(p);
                memo[tuple(`ColumnExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree ColumnExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, AllExpr, Spacing), pegged.peg.wrapAround!(Spacing, FuncExpr, Spacing), pegged.peg.wrapAround!(Spacing, FullTableExpr, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing), "SQL.ColumnExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, AllExpr, Spacing), pegged.peg.wrapAround!(Spacing, FuncExpr, Spacing), pegged.peg.wrapAround!(Spacing, FullTableExpr, Spacing), pegged.peg.wrapAround!(Spacing, FieldExpr, Spacing)), Spacing), "SQL.ColumnExpr"), "ColumnExpr")(TParseTree("", false,[], s));
        }
    }
    static string ColumnExpr(GetName g)
    {
        return "SQL.ColumnExpr";
    }

    static TParseTree AllExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), "SQL.AllExpr")(p);
        }
        else
        {
            if (auto m = tuple(`AllExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), "SQL.AllExpr"), "AllExpr")(p);
                memo[tuple(`AllExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree AllExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), "SQL.AllExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), "SQL.AllExpr"), "AllExpr")(TParseTree("", false,[], s));
        }
    }
    static string AllExpr(GetName g)
    {
        return "SQL.AllExpr";
    }

    static TParseTree FullTableExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing)), "SQL.FullTableExpr")(p);
        }
        else
        {
            if (auto m = tuple(`FullTableExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing)), "SQL.FullTableExpr"), "FullTableExpr")(p);
                memo[tuple(`FullTableExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree FullTableExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing)), "SQL.FullTableExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing)), "SQL.FullTableExpr"), "FullTableExpr")(TParseTree("", false,[], s));
        }
    }
    static string FullTableExpr(GetName g)
    {
        return "SQL.FullTableExpr";
    }

    static TParseTree FieldExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), Spacing))), "SQL.FieldExpr")(p);
        }
        else
        {
            if (auto m = tuple(`FieldExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), Spacing))), "SQL.FieldExpr"), "FieldExpr")(p);
                memo[tuple(`FieldExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree FieldExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), Spacing))), "SQL.FieldExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), Spacing))), "SQL.FieldExpr"), "FieldExpr")(TParseTree("", false,[], s));
        }
    }
    static string FieldExpr(GetName g)
    {
        return "SQL.FieldExpr";
    }

    static TParseTree StringField(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.literal!("`")), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("`")), pegged.peg.any)), pegged.peg.discard!(pegged.peg.literal!("`")))), "SQL.StringField")(p);
        }
        else
        {
            if (auto m = tuple(`StringField`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.literal!("`")), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("`")), pegged.peg.any)), pegged.peg.discard!(pegged.peg.literal!("`")))), "SQL.StringField"), "StringField")(p);
                memo[tuple(`StringField`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree StringField(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.literal!("`")), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("`")), pegged.peg.any)), pegged.peg.discard!(pegged.peg.literal!("`")))), "SQL.StringField")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.literal!("`")), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("`")), pegged.peg.any)), pegged.peg.discard!(pegged.peg.literal!("`")))), "SQL.StringField"), "StringField")(TParseTree("", false,[], s));
        }
    }
    static string StringField(GetName g)
    {
        return "SQL.StringField";
    }

    static TParseTree TableExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, AsExpr, Spacing))), "SQL.TableExpr")(p);
        }
        else
        {
            if (auto m = tuple(`TableExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, AsExpr, Spacing))), "SQL.TableExpr"), "TableExpr")(p);
                memo[tuple(`TableExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree TableExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, AsExpr, Spacing))), "SQL.TableExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, AsExpr, Spacing))), "SQL.TableExpr"), "TableExpr")(TParseTree("", false,[], s));
        }
    }
    static string TableExpr(GetName g)
    {
        return "SQL.TableExpr";
    }

    static TParseTree InputExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("{"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}"), Spacing))), "SQL.InputExpr")(p);
        }
        else
        {
            if (auto m = tuple(`InputExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("{"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}"), Spacing))), "SQL.InputExpr"), "InputExpr")(p);
                memo[tuple(`InputExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree InputExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("{"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}"), Spacing))), "SQL.InputExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("{"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}"), Spacing))), "SQL.InputExpr"), "InputExpr")(TParseTree("", false,[], s));
        }
    }
    static string InputExpr(GetName g)
    {
        return "SQL.InputExpr";
    }

    static TParseTree FuncExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.FuncExpr")(p);
        }
        else
        {
            if (auto m = tuple(`FuncExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.FuncExpr"), "FuncExpr")(p);
                memo[tuple(`FuncExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree FuncExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.FuncExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, identifier, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing)), pegged.peg.wrapAround!(Spacing, ColumnExpr, Spacing)), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "SQL.FuncExpr"), "FuncExpr")(TParseTree("", false,[], s));
        }
    }
    static string FuncExpr(GetName g)
    {
        return "SQL.FuncExpr";
    }

    static TParseTree AsExpr(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("as"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), pegged.peg.wrapAround!(Spacing, StringField, Spacing)), "SQL.AsExpr")(p);
        }
        else
        {
            if (auto m = tuple(`AsExpr`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("as"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), pegged.peg.wrapAround!(Spacing, StringField, Spacing)), "SQL.AsExpr"), "AsExpr")(p);
                memo[tuple(`AsExpr`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree AsExpr(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("as"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), pegged.peg.wrapAround!(Spacing, StringField, Spacing)), "SQL.AsExpr")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("as"), Spacing)), pegged.peg.wrapAround!(Spacing, identifier, Spacing)), pegged.peg.wrapAround!(Spacing, StringField, Spacing)), "SQL.AsExpr"), "AsExpr")(TParseTree("", false,[], s));
        }
    }
    static string AsExpr(GetName g)
    {
        return "SQL.AsExpr";
    }

    static TParseTree TerneryOp(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("between"), Spacing), "SQL.TerneryOp")(p);
        }
        else
        {
            if (auto m = tuple(`TerneryOp`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("between"), Spacing), "SQL.TerneryOp"), "TerneryOp")(p);
                memo[tuple(`TerneryOp`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree TerneryOp(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("between"), Spacing), "SQL.TerneryOp")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("between"), Spacing), "SQL.TerneryOp"), "TerneryOp")(TParseTree("", false,[], s));
        }
    }
    static string TerneryOp(GetName g)
    {
        return "SQL.TerneryOp";
    }

    static TParseTree BinaryOp(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("like"), Spacing)), "SQL.BinaryOp")(p);
        }
        else
        {
            if (auto m = tuple(`BinaryOp`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("like"), Spacing)), "SQL.BinaryOp"), "BinaryOp")(p);
                memo[tuple(`BinaryOp`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree BinaryOp(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("like"), Spacing)), "SQL.BinaryOp")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("like"), Spacing)), "SQL.BinaryOp"), "BinaryOp")(TParseTree("", false,[], s));
        }
    }
    static string BinaryOp(GetName g)
    {
        return "SQL.BinaryOp";
    }

    static TParseTree Number(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(pegged.peg.keywords!("-", "+")), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), pegged.peg.option!(pegged.peg.and!(pegged.peg.literal!("."), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')))))), "SQL.Number")(p);
        }
        else
        {
            if (auto m = tuple(`Number`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(pegged.peg.keywords!("-", "+")), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), pegged.peg.option!(pegged.peg.and!(pegged.peg.literal!("."), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')))))), "SQL.Number"), "Number")(p);
                memo[tuple(`Number`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Number(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(pegged.peg.keywords!("-", "+")), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), pegged.peg.option!(pegged.peg.and!(pegged.peg.literal!("."), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')))))), "SQL.Number")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(pegged.peg.keywords!("-", "+")), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), pegged.peg.option!(pegged.peg.and!(pegged.peg.literal!("."), pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')))))), "SQL.Number"), "Number")(TParseTree("", false,[], s));
        }
    }
    static string Number(GetName g)
    {
        return "SQL.Number";
    }

    static TParseTree String(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(quote), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(quote), pegged.peg.any)), pegged.peg.discard!(quote))), "SQL.String")(p);
        }
        else
        {
            if (auto m = tuple(`String`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(quote), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(quote), pegged.peg.any)), pegged.peg.discard!(quote))), "SQL.String"), "String")(p);
                memo[tuple(`String`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree String(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(quote), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(quote), pegged.peg.any)), pegged.peg.discard!(quote))), "SQL.String")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.discard!(quote), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(quote), pegged.peg.any)), pegged.peg.discard!(quote))), "SQL.String"), "String")(TParseTree("", false,[], s));
        }
    }
    static string String(GetName g)
    {
        return "SQL.String";
    }

    static TParseTree Spacing(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(blank)), "SQL.Spacing")(p);
        }
        else
        {
            if (auto m = tuple(`Spacing`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(blank)), "SQL.Spacing"), "Spacing")(p);
                memo[tuple(`Spacing`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Spacing(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(blank)), "SQL.Spacing")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(blank)), "SQL.Spacing"), "Spacing")(TParseTree("", false,[], s));
        }
    }
    static string Spacing(GetName g)
    {
        return "SQL.Spacing";
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(SelectStmt(p));
        result.children = [result];
        result.name = "SQL";
        return result;
    }

    static TParseTree opCall(string input)
    {
        if(__ctfe)
        {
            return SQL(TParseTree(``, false, [], input, 0, 0));
        }
        else
        {
            forgetMemo();
            return SQL(TParseTree(``, false, [], input, 0, 0));
        }
    }
    static string opCall(GetName g)
    {
        return "SQL";
    }


    static void forgetMemo()
    {
        memo = null;
    }
    }
}

alias GenericSQL!(ParseTree).SQL SQL;

