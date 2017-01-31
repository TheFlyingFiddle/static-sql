module sql.test;

version(unittest):

import sql.attributes;
import sql.query;

alias URL = Varchar!(50);

@Database("rss_client")
struct RSSDatabase
{
    struct Users
    {
        @Primary @AutoIncrement
        int id;

        @Unique
        ulong googleID;
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
