---
layout: post
title: "PostGIS and Rails: A Simple Approach"
date: 2013-08-18
---

PostGIS is a geospatial extension library for PostgreSQL that allows you to perform a ton of geometric and geographic operations on your data at high speeds. For example:

1. Compute the distance between two points
2. Find all the points within X meters of point P
3. Determine which points are enclosed in polygon P
4. A million other things

In Ruby land, there is a gem called [RGeo](http://rdoc.info/gems/rgeo/frames) that provides a ton of objects and methods for handling Geospatial objects. In Rails, there are a number of ActiveRecord adapters for each database driver that serialize and deserialize these objects to and from their natural types in the database and RGeo types (for example, [activerecord-postgis-adapter](http://rdoc.info/gems/activerecord-postgis-adapter/frames)).

They are both great and powerful gems that can handle the majority (if not all) of the kinds of things you'd like to do with a geospatial database.

However, since Rails doesn't have hooks in place to extend the existing drivers with new ways to handle new data types, the ActiveRecord drivers are a (well maintained) collection of subclasses with key methods copied and modified from the originals.

This means that they are [difficult to setup and can be hard to use](https://github.com/dazuma/activerecord-postgis-adapter/blob/master/Documentation.rdoc). However, it certainly can be done.

## A Simpler Approach

Despite the enormous power of these libraries, I tend to only need one or two features, and it's usually the simple stuff. Like "Find all the bars near the current user".

<strong>In this post, we're going to explore how to use PostGIS with Rails with a few snippets of raw SQL and a couple of advanced PostgreSQL features.</strong>

## 1. Setup

First off, you should have Ruby 2 and Rails 4 already installed. If not, go look for guides on that first.

PostgreSQL ships with all the major linux distributions, and is available via homebrew on a Mac. However, **that's not how you want to install them**.

### OS X

On OS X, the best way to get PostgreSQL with PostGIS and other advanced features is with Heroku's [PostgreSQL.app](http://postgresapp.com/).

**[Currently, the most recent build is having problems with PostGIS (issue #109)](https://github.com/PostgresApp/PostgresApp/issues/109)**. In the mean time, use this link to run a previous build of PostgreSQL.app:

[http://postgres-app.s3.amazonaws.com/PostgresApp-9-2-2-0.zip](http://postgres-app.s3.amazonaws.com/PostgresApp-9-2-2-0.zip)

Once issue #109 is resolved, the current build should work.

### Linux

On linux, most package managers are lagging a bit behind the current PostgreSQL version. PostgreSQL has setup repositories for BSD, the RedHat family, Debian/Ubuntu, SuSE, and more [on their download page](http://www.postgresql.org/download/).

On Debian and Ubuntu, you'll want to use their apt repository. Edit `/etc/apt/sources.list.d/pgdg.list` and paste:

<pre>
deb http://apt.postgresql.org/pub/repos/apt/ YOUR_UBUNTU_VERSION_HERE-pgdg main
</pre>

Then, import the repository key:

<pre>
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo apt-key add -
sudo apt-get update
</pre>

Finally, install PostgreSQL 9.2, the contrib package, and PostGIS 2.0 scripts:

<pre>
sudo apt-get install postgresql-9.2 postgresql-contrib-9.2 postgresql-server-dev-9.2 postgresql-9.2-postgis-2.0-scripts
</pre>

(Note that if you have a previous version of PostgreSQL installed side-by-side, PostgreSQL 9.2 may run on a non-standard port so as not to conflict with the old version)

### Test your installation

To test your installation, make a database and attempt to enable PostGIS:

<pre>
$ psql
psql (9.2.4)
Type "help" for help.

nick=# create database postgis_test;
CREATE DATABASE
nick=# \c postgis_test
You are now connected to database "postgis_test" as user "nick".
postgis_test=# create extension postgis;
CREATE EXTENSION
postgis_test=# 
</pre>

If it doesn't complain, it worked!

## 2. Refuelly

In order to demonstrate the steps involved, we need a demo project. We'll be writing an app called Refuelly that will help users find the nearest place to get coffee. We won't build the whole app, just the models necessary to ask the following question: "What are the top 10 closest places to a given location?"

Let's make the app:

<pre>
$ rails new refuelly -d postgresql
      create  
      create  README.rdoc
      create  Rakefile
      create  config.ru
      ... etc ...
$ cd refuelly
$ bundle update
</pre>

At this point, I edited the `config/database.yml` to suit my machine. I'm in linux, so I simply removed the username and password since I have myself setup as a superuser.

Since we will be using some raw SQL, we need to switch from a `schema.rb` to a `structure.sql`. This means that in development, we're going to save our database snapshot in raw SQL, not Rails's Ruby representation.

Edit `config/application.rb` and add this line inside the `class Application` near the other commented out config statements:

<pre class='prettyprint'>
config.active_record.schema_format = :sql
</pre>

Now, create the database and a structure file should exist:

<pre>
$ rake db:create db:migrate
$ ls db/structure.sql 
db/structure.sql
</pre>

Great, now our app is setup with PostgreSQL. This is a good time to commit your code.

## 2. Cafe

We need a `Cafe` model to represent a coffee shop. It will have a `name`, `latitude`, and `longitude`. Let's create it:

<pre>
$ rails generate model cafe \
    name:string "latitude:decimal{9,6}" "longitude:decimal{9,6}" \
    --fixture false
      invoke  active_record
      create    db/migrate/20130818184035_create_caves.rb
      create    app/models/cafe.rb
      invoke    test_unit
      create      test/models/cafe_test.rb
</pre>

We're going to store latitude and longitude as decimal types with precision 9 and scale 6. That means there will be a total of 6 digits right of the decimal, and 9 total digits. PostgreSQL will secretly store this as an integer with an order of magnitude (like scientific notation). That way, there are no floating point errors. This is what the PostgreSQL `money` type is, under the hood. That way, it keeps the decimal point in the right place for us and doesn't lose precision.

Hilariously, Rails pluralizes cafe to caves, so real quick **edit the migration and change it to cafes** (don't forget to rename the file too). If you're a stickler like me, you should also mark every column `null: false`. Also, edit `app/models/cafe.rb` and add:

<pre class='prettyprint'>self.table_name = "cafes"</pre>

Now, migrate:

<pre>
$ rake db:migrate
==  CreateCafes: migrating ====================================================
-- create_table(:cafes)
   -> 0.0141s
==  CreateCafes: migrated (0.0143s) ===========================================
</pre>

Now is another great time to commit.

## 3. Query on computed points

Our next goal is to be able to create some cafes and then query to find the closest ones to a given point. So, let's write a test to help us develop the code. Inside `test/models/cafe_test.rb` add:

<pre class='prettyprint'>
test "close cafes" do
  far_cafe = Cafe.create!(
    name:      "Far Cafe",
    latitude:   40.000000,
    longitude: -77.000000
  )

  close_cafe = Cafe.create!(
    name:      "Close Cafe",
    latitude:   39.010000,
    longitude: -75.990000
  )

  close_cafes = Cafe.close_to(39.000000, -76.000000).load

  assert_equal 1,          close_cafes.size
  assert_equal close_cafe, close_cafes.first
end
</pre>

Here we're creating two cafes and we expect the close cafe to be `close_to` the point, but not the far one.

(p.s., we're calling `load` for prettier sql for later, normally this is *not* a good idea)

To solve this, we need to do two things. First, add PostGIS:

<pre>
$ rails generate migration enable_postgis
</pre>

Edit the migration, and write:

<pre class='prettyprint'>
class EnablePostgis < ActiveRecord::Migration
  def change
    enable_extension :postgis
  end
end
</pre>

`enable_extension` is new in Rails 4, and it abstracts PostgreSQL's extension commands for us. Nice!

Next, we need to write our scope on `Cafe`:

<pre class='prettyprint'>
scope :close_to, -> (latitude, longitude, distance_in_meters = 2000) {
  where(%{
    ST_DWithin(
      ST_GeographyFromText(
        'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'
      ),
      ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
      %d
    )
  } % [longitude, latitude, distance_in_meters])
}
</pre>

This should pass our test. Let's talk about what's going on.

We're making a `where` scope on `Cafe` that uses the `ST_DWithin` function to find all the cafes with a certain distance of a given point. The third parameter here is the distance in meters, and our default is 2km.

Then, we're providing two point objects via `ST_GeographyFromText`. This function converts some text in Well Known Text (WKT) format to the binary format used by PostGIS to represent points. An example of WKT would be `SRID=4326;POINT(-76.000000 39.000000)`. The first parameter sets the SRID to 4326 (a projection representing the whole globe) and then builds a string for a point featuring the cafe's longitude and latitude. This builds a point on the fly for each cafe in the cafes table.

The second point object builds a point using the parameters passed in to the scope lambda, the lat and lon. We use Ruby's built-in string interpolation to easily encode two floating point numbers. It's safe and it let's us avoid ActiveRecord's quoting, which would mess up the SQL.

As you can see, I'm computing everything on the fly. That means whenever this query is run, we're converting all the cafes' latitudes and longitudes into points and also converting our query point into a point, then scanning every cafe and manually computing distance. This is super slow.

But it passes our test. Commit!

## 4. At scale

OK, so it works, but it's probably slow (we don't really know yet how slow, do we?). So, let's investigate!

First, we need some test data. Open up a psql console and insert 1 million random cafes:

<pre>
$ rails dbconsole
psql (9.2.4)
Type "help" for help.

refuelly_development=#
insert into cafes (name, latitude, longitude) (
  select 'Cafe ' || i as name, 39 + x.lat as latitude, -76 - x.lon as longitude
  from (
    select i, random() * 10 as lat, random() * 10 as lon
    from generate_series(1,1000000) as i
  )                                                            
as x );
</pre>

For speed, we do this in PostgreSQL so that Rails doesn't chug along making model objects. We're making a million restaurants within 10 minutes of `39, -76`.

Now, when we ran our test, you can look in the logs to find the query Rails puts together. It looks like this:

<pre class='prettyprint'>
SELECT "cafes".* FROM "cafes" WHERE (
 ST_DWithin(
 ST_GeographyFromText(
 'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'
 ),
 ST_GeographyFromText('SRID=4326;POINT(-76.000000 39.000000)'),
 2000
 )
 )
</pre>

Simply copy and paste that into your postgresql console (and a semicolon), and it should output the result. I happened to get 8 rows, and it took my computer around 3 seconds.

Let's use PostgreSQL's built-in `EXPLAIN` and `ANALYZE` tools:

<pre>
refuelly_development=# EXPLAIN ANALYZE SELECT "cafes".* FROM "cafes" WHERE (
 ST_DWithin(
 ST_GeographyFromText(
 'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'
 ),
 ST_GeographyFromText('SRID=4326;POINT(-76.000000 39.000000)'),
 2000
 )

 Seq Scan on cafes  (cost=0.00..355927.00 rows=37036 width=47) (actual time=612.698..3435.187 rows=8 loops=1)
   Filter: ((snipped))
   Rows Removed by Filter: 999992
 Total runtime: 3435.256 ms
</pre>

As you can see from the first line, we're doing a Sequence Scan, which means we're looking at *every single cafe*. Then we have a filter (I removed it from the output) which is our distance query and checks each cafe. Finally, you can see the total runtime of ~3.4 seconds.

Yup. It's slow.

## 5. Indexing

So, now what? Normally, we'd store the cafe's `location` as a computed point field of the latitude and longitude. However, that's going to be really annoying because rails will get really confused trying to treat that point field like a string. This is the pain that the activerecord-postgis-adapter family of gems help fix.

But, we're going to do something much more awesome and clever. We're going to use PostgreSQL's ability to index on expressions.

Unlike MySQL, PostgreSQL allows you to build an index on any expression you want. The simplest expression would simply be a column name, like this:

<pre class='prettyprint'>
create index index_users_on_email on users (email)
</pre>

The chunk inside the parens is the expression. So, if you always searched users by their lowercased email, you could make an optimized index just for that function, like this:

<pre class='prettyprint'>
create index index_users_on_email on users (lower(email))
</pre>

Now, postgresql will keep an index filled with downcased email addresses that are ready to be queried without having to perform the lowering at runtime. Sweet.

So, what we're going to do is **index on a point built from cafe's longitude and latitude**. It's pretty easy, we just copy our SQL fragment from our query and turn it into an index:

<pre>
$ rails generate migration add_point_index_to_cafes
</pre>

Edit the migration and write:

<pre class='prettyprint'>
class AddPointIndexToCafes < ActiveRecord::Migration
  def up
    execute %{
      create index index_on_cafes_location ON cafes using gist (
        ST_GeographyFromText(
          'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'
        )
      )
    }
  end

  def down
    execute %{drop index index_on_cafes_location}
  end
end
</pre>

Our index's expression will be a point built from the latitude and longitude. Now, when our distance query asks for this built point, our index will match the query and be usable for our distance calculation.

Migrate your database (this will take a little bit because it has to index the million points already in the db, for me it took 18 seconds)

<pre>
$ rake db:migrate

==  AddPointIndexToCafes: migrating ===========================================
-- execute("\n      create index index_on_cafes_location ON cafes using gist (\n        ST_GeographyFromText(\n          'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'\n        )\n      )\n    ")
   -> 18.7678s
==  AddPointIndexToCafes: migrated (18.7680s) =================================
</pre>

Now, let's re-run our explained distance query:

<pre>
refuelly_development=# explain analyze SELECT "cafes".* FROM "cafes" WHERE (
 ST_DWithin(
 ST_GeographyFromText(
 'SRID=4326;POINT(' || cafes.longitude || ' ' || cafes.latitude || ')'
 ),
 ST_GeographyFromText('SRID=4326;POINT(-76.000000 39.000000)'),
 2000
 )
 )

 Bitmap Heap Scan on cafes  (cost=13665.84..133655.39 rows=37036 width=47) (actual time=0.543..1.054 rows=10 loops=1)
   Recheck Cond: (cafe within distance bounding box of point)
   Filter: (cafe within distance bounding box of point and within exact distance of point)
   Rows Removed by Filter: 4
   ->  Bitmap Index Scan on index_on_cafes_location  (cost=0.00..13656.58 rows=333330 width=0) (actual time=0.119..0.119 rows=14 loops=1)
         Index Cond: (cafe within distance bounding box of point)
 Total runtime: 1.155 ms
</pre>

Boom, 1ms for the query. If you look at the explain output, you'll see we're now doing (from the bottom up) a bitmap index scan using our index (it does a pass with just a bounding box for speed), then a filter with exact distance, then it rechecks with the bounding box.

## 6. Conclusion

In conclusion, there are a number of pros and cons to this solution.

It's great that on our `Cafe` we simply use `latitude` and `longitude` attributes. No serializers, factories, or callbacks involved. Rails is perfectly happy.

There are no extra gems needed, which means no extra dependencies, version lag, or compatibility issues with the driver.

Indexing can be done and queries are very fast.

However, we did have to hand-write a bunch of SQL, which is always less than optimal. In this case, I'm OK with it, because PostGIS is really the best tool for the job here. We also have to keep the SQL in our query synchronized with our index, but that's the case with any index on an expression.

All-in-all, I prefer this solution because it's smaller, simpler, and lighter weight for accomplishing simple tasks with geospatial data on Rails.

## Source Code

The source code resulting from this post is available at [github.com/ngauthier/postgis-on-rails-example](http://github.com/ngauthier/postgis-on-rails-example).
