---
layout: post
title: Scraping the Web with Ruby
date: 2014-06-05
---

When you run into a site that doesn't have an API, but you'd like to use the site's data, sometimes all you can do is scrape it! In this article, we'll cover using Capybara and PhantomJS along with some standard libraries like CSV, GDBM, and OpenStruct to turn a website's content into CSV data.

As an example, I'll be scraping my own site. Keep in mind if you are planning to scrape a site, be aware of their Terms of Service. Many sites don't allow scraping, so be a good web citizen and respect the wishes of the site's owners.

Our goal here is to dump out a CSV file of the blog articles here on ngauthier.com that contains the titles, dates, urls, summary, and full body text. Let's get started!

# 1. Scraping with Capybara

The first thing we're going to do is get Capybara running and just dump the fields from the front page out to the screen to make sure everything's working.

First, we're going to load up capybara and poltergeist. Poltergeist is a ruby gem that wraps phantomjs so that we can run a real browser on the external pages.

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'

include Capybara::DSL
Capybara.default_driver = :poltergeist
</pre>

Next up, we're going to visit my site. Then we'll iterate over every post and pull out the fields we want using css selectors and dump them to the screen.

<pre class='prettyprint'>
visit "http://ngauthier.com/"

all(".posts > .post").each do |post|
  title = post.find("h3 a").text
  url   = post.find("h3 a")["href"]
  date  = post.find("h3 small").text
  summary = post.find("p.preview").text

  puts title
  puts url
  puts date
  puts summary
  puts ""
end
</pre>

When we run it, we can see that our scraper is loading up the homepage and finding the info:

<pre>
Using Docker to Parallelize Rails Tests
/2013/10/using-docker-to-parallelize-rails-tests.html
2013-10-13
Docker is a new way to containerize services. The primary use so far has been for deploying services in a very thin container. I experimented with using it for Rails Continuous Integration so that I could run tests within a consistent environment, and then I realized that the containers provide excellent encapsulation to allow for parallelization of test suites. There are three things we'll have to do to run a Rails test suite in parallel in docker: Create a Dockerfile for a system that ca...

PostGIS and Rails: A Simple Approach
/2013/08/postgis-and-rails-a-simple-approach.html
2013-08-18
PostGIS is a geospatial extension library for PostgreSQL that allows you to perform a ton of geometric and geographic operations on your data at high speeds. For example: Compute the distance between two points Find all the points within X meters of point P Determine which points are enclosed in polygon P A million other things In Ruby land, there is a gem called RGeo that provides a ton of objects and methods for handling Geospatial objects. In Rails, there are a number of ActiveRecord ...

...
</pre>

# Exporting CSV

Our next goal is to export some CSV. All we'll do is load up the `csv` standard library and write csv to standard out.

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'

include Capybara::DSL
Capybara.default_driver = :poltergeist

visit "http://ngauthier.com/"

CSV do |csv|
  csv << ["Title", "URL", "Date", "Summary"]
  all(".posts > .post").each do |post|
    title = post.find("h3 a").text
    url   = post.find("h3 a")["href"]
    date  = post.find("h3 small").text
    summary = post.find("p.preview").text

    csv << [title, url, date, summary]
  end
end
</pre>

Now, our program is unixy, so we would run it and redirect its output to a csv file of our choosing. Nice!

# Full Articles via Multi-Pass

So far, we've only pulled the summaries of the posts, but we want the whole content. For this, we're going to need to do a two-pass scrape. First, we'll scrape the summaries like we already are doing. Second, we'll visit each post's url and grab the post's body.

To do this, we're going to keep track of an `articles` array, and store the articles temporarily as hashes.

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'

include Capybara::DSL
Capybara.default_driver = :poltergeist

visit "http://ngauthier.com/"

articles = []

# Pass 1: summaries and info
all(".posts > .post").each do |post|
  title = post.find("h3 a").text
  url   = post.find("h3 a")["href"]
  date  = post.find("h3 small").text
  summary = post.find("p.preview").text

  articles << {
    title:   title,
    url:     url,
    date:    date,
    summary: summary
  }
end

# Pass 2: full body of article
articles.each do |article|
  visit "#{article[:url]}"
  article[:body] = find("article").text
end

# Output CSV
CSV do |csv|
  csv << ["Title", "URL", "Date", "Summary", "Body"]
  articles.each do |article|
    csv << [
      article[:title],
      article[:url],
      article[:date],
      article[:summary],
      article[:body]
    ]
  end
end
</pre>

That wasn't so bad! The main issue now is robustness. My blog is fast (static sites with jekyll woo!) and I only have a couple posts. But imagine the scrape took an hour. If anything crashed, took too long, or the site went down, we'd waste a ton of time.

# Handling Interruptions with GDBM

Enter GDBM. GDBM is a standard unix library that is a simple file-based key-value store. It's like a hash, but you can only use strings as the values. What we're going to do is replace our article array with a GDBM store. For the key we'll use the url, and for the value we'll dump the article to JSON.

Now, if the program crashes, when we resume we want to skip over any articles we've already processed. Let's take a look:

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'
require 'gdbm'

include Capybara::DSL
Capybara.default_driver = :poltergeist

visit "http://ngauthier.com/"

articles = GDBM.new("articles.db")
</pre>

We've required gdbm and now `articles` is a GDBM store in a file in the current directory called `articles.db`. We can now use `articles` like a hash, and GDBM will sync it to the file system whenever we write to a key. Neat!

<pre class='prettyprint'>
# Pass 1: summaries and info
all(".posts > .post").each do |post|
  title = post.find("h3 a").text
  url   = post.find("h3 a")["href"]
  date  = post.find("h3 small").text
  summary = post.find("p.preview").text

  next if articles[url]

  articles[url] = JSON.dump(
    title:   title,
    url:     url,
    date:    date,
    summary: summary
  )
end
</pre>

Now, we have a `next if` that checks to see if we already have the article. We don't want to store it if we already have it, because that would overwrite the article (and we may have fetched the body).

When we store it, we `JSON.dump` our hash so that it's a string.

<pre class='prettyprint'>
# Pass 2: full body of article
articles.each do |url, json|
  article = JSON.load(json)
  next if article["body"]
  visit url
  has_content?(article["title"]) or raise "couldn't load #{url}"
  article["body"] = find("article").text
  articles[url] = JSON.dump(article)
end
</pre>

When we iterate a GDBM store it gives us a key-value pair, like a hash. So, we have to load up the article from JSON before we can work with it. Our keys also become strings instead of symbols, because it was loaded from JSON.

We have another `next if` that skips visiting the page if we have the body already. Additionally, we check the page for the title. This gives the page time to load, as opposed to accidentally scraping the last page's content.

Finally, we have to dump the article to JSON to store it again.

<pre class='prettyprint'>
# Output CSV
CSV do |csv|
  csv << ["Title", "URL", "Date", "Summary", "Body"]
  articles.each do |url, json|
    article = JSON.load(json)
    csv << [
      article["title"],
      article["url"],
      article["date"],
      article["summary"],
      article["body"]
    ]
  end
end
</pre>

When we output to CSV, we have to load up the JSON to construct our CSV output.

Now that GDBM is running, the first time I ran the scrape it took 7.3 seconds, and the second time, it took 1.7 seconds because it only hit the index and skipped scraping. I can also ctrl-c the program while it's working, and re-run it and it will resume. Nice!

# Object Oriented

OK at this point the code is pretty ugly and scripty, and some things are getting annoying. Let's clean up this code.

## First Pass: Base Class, Instance Variables and Method Splitting

First off, we're doing everything in the global scope, and Capybara complains every time we include `Capybara::DSL` in the global scope because it extends it with methods like `find` and `visit`. Convenient, but messy. Let's create a base class called `NickBot` and we'll split up each phase into a method for readability.

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'
require 'gdbm'

class NickBot
  include Capybara::DSL

  def initialize(io = STDOUT)
    Capybara.default_driver = :poltergeist
    @articles = GDBM.new("ngauthier.db")
    @io = io
  end

  def scrape
    get_summaries
    get_bodies
    output_csv
  end

  def get_summaries
    visit "http://ngauthier.com/"
    all(".posts > .post").each do |post|
      title = post.find("h3 a").text
      url   = post.find("h3 a")["href"]
      date  = post.find("h3 small").text
      summary = post.find("p.preview").text

      next if @articles[url]

      @articles[url] = JSON.dump(
        title:   title,
        url:     url,
        date:    date,
        summary: summary
      )
    end
  end

  def get_bodies
    @articles.each do |url, json|
      article = JSON.load(json)
      next if article["body"]
      visit "http://ngauthier.com#{url}"
      has_content?(article["title"]) or raise "couldn't load #{url}"
      article["body"] = find("article").text
      @articles[url] = JSON.dump(article)
    end
  end

  def output_csv
    CSV(@io) do |csv|
      csv << ["Title", "URL", "Date", "Summary", "Body"]
      @articles.each do |url, json|
        article = JSON.load(json)
        csv << [
          article["title"],
          article["url"],
          article["date"],
          article["summary"],
          article["body"]
        ]
      end
    end
  end
end

NickBot.new(STDOUT).scrape
</pre>

OK, that's better, but really all we did was push our veggies around our plate. We didn't eat any of them.

## Second Pass: Article Class

Let's start with an `Article` that will wrap up parsing a Capybara node and dumping itself automatically. GDBM calls an object's `to_str` to dump it, so we can hook in there to dump ourselves to JSON:

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'
require 'gdbm'

class NickBot
  include Capybara::DSL

  def initialize(io = STDOUT)
    Capybara.default_driver = :poltergeist
    @articles = GDBM.new("ngauthier.db")
    @io = io
  end

  def scrape
    get_summaries
    get_bodies
    output_csv
  end

  def get_summaries
    visit "http://ngauthier.com/"
    all(".posts > .post").each do |post|
      article = Article.from_summary(post)
      next if @articles[article.url]
      @articles[article.url] = article
    end
  end

  def get_bodies
    @articles.each do |url, json|
      article = Article.new(JSON.load(json))
      next if article.body
      visit "http://ngauthier.com#{url}"
      has_content?(article.title) or raise "couldn't load #{url}"
      article.body = find("article").text
      @articles[url] = article
    end
  end

  def output_csv
    CSV(@io) do |csv|
      csv << ["Title", "URL", "Date", "Summary", "Body"]
      @articles.each do |url, json|
        article = Article.new(JSON.load(json))
        csv << [
          article.title,
          article.url,
          article.date,
          article.summary,
          article.body
        ]
      end
    end
  end

  class Article < OpenStruct
    def self.from_summary(node)
      new(
        title:   node.find("h3 a").text,
        url:     node.find("h3 a")["href"],
        date:    node.find("h3 small").text,
        summary: node.find("p.preview").text,
      )
    end

    def to_str
      to_h.to_json
    end
  end
end

NickBot.new(STDOUT).scrape
</pre>

We're using OpenStruct here to cheaply get a hash-to-object conversion so we can use dot notation to access fields. This makes it feel way more like an object. It also means we could replace the accessors later transparently.

This is better, but we still have a few issues with entanglement between NickBot and Article:

1. NickBot has to remember to *load* an Article from JSON
1. NickBot holds the database information where Articles are stored
1. NickBot has to know how GDBM works in order to iterate

Let's clean this up next.

## Third Pass: Active Record Pattern

We're going to implement the Active Record Pattern. No, I'm not going to `require 'activerecord'`, I'm talking about the classic [Active Record Pattern](http://en.wikipedia.org/wiki/Active_record_pattern) from *Patterns of Enterprise Application Architecture*. The key here is to mix in the database behavior with the Article class so it can handle iteration, storage, and retrieval without NickBot having to understand how it works.

<pre class='prettyprint'>
#!/usr/bin/env ruby

require 'capybara'
require 'capybara/poltergeist'
require 'csv'
require 'gdbm'

class NickBot
  include Capybara::DSL

  def initialize(io = STDOUT)
    Capybara.default_driver = :poltergeist
    @io = io
  end

  def scrape
    visit "http://ngauthier.com/"
    all(".posts > .post").each do |post|
      article = Article.from_summary(post)
      next unless article.new_record?
      article.save
    end

    Article.each do |article|
      next if article.body
      visit "http://ngauthier.com#{article.url}"
      has_content?(article.title) or raise "couldn't load #{url}"
      article.body = find("article").text
      article.save
    end

    CSV(@io) do |csv|
      csv << ["Title", "URL", "Date", "Summary", "Body"]
      Article.each do |article|
        csv << [
          article.title,
          article.url,
          article.date,
          article.summary,
          article.body
        ]
      end
    end
  end
</pre>

Let's start looking at the usage of Article above. We've added `Article#new_record?`, `Article#save`, and `Article.each`. But also notice that NickBot no longer has an `@articles` instance variable. Cool! Now NickBot doesn't care at all how Articles are persisted.

Let's take a look at our new Article class.

<pre class='prettyprint'>
  class Article < OpenStruct
    DB = GDBM.new("articles.db")

    def self.from_summary(node)
      new(
        title:   node.find("h3 a").text,
        url:     node.find("h3 a")["href"],
        date:    node.find("h3 small").text,
        summary: node.find("p.preview").text,
      )
    end

    def self.each
      DB.each do |url, json|
        yield Article.new(JSON.load(json))
      end
    end

    def save
      DB[url] = to_h.to_json
    end

    def new_record?
      DB[url].nil?
    end
  end
end
</pre>

It still inherits from OpenStruct, because that gives us our `initialize(attributes)` and `to_h` for cheap. But now we have a `DB` constant that is set when the code loads up and connects to our GDBM file. This simple constant allows the Article class and also Article instances to access the GDBM database file.

We can now write an easy `each` that iterates the database and does the JSON load. We can also write our `save` that dumps using JSON. The `new_record?` is simply a check for an existing key.

The cool thing is, we could switch our GDBM implementation our for any other type of persistence. We could be using PostgreSQL if we needed more structure, or maybe Redis if we wanted to run it on Heroku with minimal changes.

# Wrap-up

I've found GDBM to be a really useful little library, because when I am writing utility scripts I don't want to maintain a PostgreSQL database, but I also need some persistence and reliability. It's a great step up from writing to csv repeatedly (which is pretty slow and also error prone when the program crashes during a write!).

I continue to find wonderful nuggets of awesome in Ruby's standard library all the time!

[Final source code available as a gist](https://gist.github.com/ngauthier/0f78598f2aaecab8f1bc).
