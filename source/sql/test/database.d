module sql.test.database;

version(unittest):

import sql.attributes;
alias URL = Varchar!(50);

@Database("my_test_db")
struct RSSDatabase
{
    struct Users
    {
        @Primary @AutoIncrement
        int id;

        @Unique
        int googleID;
    }

    struct Feeds
    {
        @Primary
        URL url;

        string title;
        string description;
    }

    struct Subs
    {
        @Primary @NotNull
        int user;

        @Primary @NotNull
        URL feed;
    }

    struct Items
    {
        @Primary
        URL url;

        @Foreign!(Feeds.url)
        URL feed;
        string title;
        string description;
    }
}
