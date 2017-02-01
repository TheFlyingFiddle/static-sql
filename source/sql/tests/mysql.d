module sql.tests.mysql;
version(unittest):

import std.stdio;
import mysql;
import sql.database;
import sql.query;
import sql.tests.database;
import sql.tests.query;

enum userstring = "host=localhost;user=root;pwd=warhammer2;port=8888";

alias OrderedUsers = SQLQuery!(RSSDatabase, q{
	select * from users where id > {id}
	order by id desc
});

alias UpdateGoogleID = SQLUpdate!(RSSDatabase, q{
	update users
	set googleID = {newID}
	where id = {id}
});


//Update is not a query
unittest
{
	/+
	auto query = SQLQuery!(RSSDatabase, q{
	   select users.name from users; 
	});

	auto updator = SQLQuery!(RSSDatabase, q{
	   update users
	   set users.name = {newName}
	   where users.name = {oldName}
	});

	foreach(name; query.query(con))
	{
		auto fixedName = name.capitalize();
		if(name != fixedName)
		{
			updator.oldName = name;
			updator.newName = fixedName;
			updator.update(con);
		}
	}	 +/
}


unittest
{
    auto client = new MySQLClient(userstring);
    auto con    = client.lockConnection();
    setupDatabase!(RSSDatabase)(con);

	auto inserter = SQLInsertOrUpdate!(RSSDatabase.Users, "googleID")();
	inserter.googleID = 12351;
	inserter.insert(con);

	auto query = OrderedUsers(1);
	auto update = UpdateGoogleID();
	update.id = 1;
	update.newID = 200;
	update.update(con);
	query = OrderedUsers(0);
	writeln("After Update: ", query.query(con));

	//What would I like inserts to look like?
	//auto insert = InsertUser(con);
	//insert.values(iota(0, 100));
	auto result = query.query(con);
	query.id = 10;
	auto result2 = query.query(con);

    writeln("First Result: ", result);
	writeln("Second Result: ", result2);


}
