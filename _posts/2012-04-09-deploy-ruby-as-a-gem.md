---
layout: post
title: Deploy Ruby as a Gem
date: 2012-04-09
---

## Background

I was looking at [git-deploy](https://github.com/mislav/git-deploy) and it looks really awesome. But it got me thinking: We have tools like `bundler` and `rack` that can handle gem versioning and dependencies, and creating clean interfaces for web applications. Why can't we use those tools for deploying our own code?

I think ruby gems are a great way of packaging code up, and that any code you write should become a gem if it needs to be re-used. Gems are pretty easy to write, and they automatically help you package and version your code.

I also think we should be doing more version-based deploys of code. Even if it's just a git tag. But it's better if it's actually an application version.

So, I stumbled across [Running Sinatra inside a Ruby Gem](http://florianhanke.com/blog/2011/02/02/running-sinatra-inside-a-gem.html) by Florian Hanke, and I really liked it, but I wanted to take it one step further: deploying.

## Application Setup

The first thing we have to do is setup our application:

<pre class='prettyprint'>
bundle gem awesome_site
</pre>

That will make a gem scaffold inside the `awesome_site` folder for a gem called `AwesomeSite`. Next, in `awesome_site.gemspec` add:


<pre class='prettyprint'>
gem.add_dependency 'sinatra', '1.3.2'
</pre>

Also, update the `gem.description` and `gem.summary`.

Next, we're going to add a `config.ru`, which will help us test our application in development:

<pre class='prettyprint'>
require 'rubygems'
require 'bundler'
Bundler.setup
require 'awesome_site'
run AwesomeSite::App
</pre>

So, we need to setup `AwesomeSite::App` as a rack app. Edit `lib/awesome_site.rb` to autoload `App`:

<pre class='prettyprint'>
module AwesomeSite
  autoload :App, 'awesome_site/app'
end
</pre>

Then put this in `lib/awesome_site/app.rb`:


<pre class='prettyprint'>
require 'sinatra'
module AwesomeSite
  class App < Sinatra::Base
    get '/' do
      'hello world!'
    end
  end
end
</pre>

Note that I used `autoload` instead of `require` for `App` and I also didn't `require` `Sinatra` until the `app.rb` file. This means that loading my gem will be fast, and that `sinatra` won't have its code loaded and run until the `App` is needed. This will keep boot times down (like when unit testing code that doesn't need `App`).

Now, you should be able to run `rackup` and visit the app!

The last thing we need to do is `rake install` to build and install the gem on our local system.

## Server Setup

OK, so now that we have our great app as a gem (thanks Florian!) it's time to setup the server. Make a new directory (to simulate the server's application folder) outside of the `awesome_site` folder. I just called mine `server`. In this folder, make a `Gemfile`:

<pre class='prettyprint'>
source :rubygems
source 'http://0.0.0.0:8808'
gem 'awesome_site'
</pre>

This `Gemfile` shows how I would install `awesome_site` from a local gem server (by running `gem server`) and pull dependencies from rubygems.org. An alternative would be:

<pre class='prettyprint'>
source :rubygems
gem 'awesome_site', :git => 'git://github.com/ngauthier/awesome_site.git'
</pre>

That could pull the gem from github, but that's suboptimal because you would have to also send a `:ref` in order to set the version, which would be a pain in the next section.

A third option would be to build the gem locally and `scp` it to the server and install, but that doesn't use all the fun bundler stuff!

You can use [geminabox](http://guides.rubygems.org/run-your-own-gem-server/) to run your own gem server that you can push gems too.


OK, now we need a `config.ru` file for the server. It's the same as `awesome_site`'s `config.ru`:

<pre class='prettyprint'>
require 'rubygems'
require 'bundler'
Bundler.setup
require 'awesome_site'
run AwesomeSite::App
</pre>

Now, we can run `bundle` and `rackup` and we're running our server based off our gem!

## Deployment

As mentioned previously, you need to push the gem to your own gem server. That means either your gem server can check out the latest code and install the gem, or simply use `geminabox` to let developers push a gem. So the deployment steps would be:

1. Update `awesome_site` in some way, and set `AwesomeSite::VERSION` to an updated number.
1. `rake build`
1. `gem inabox ./pkg/awesome_site-1.0.0.gem` (then enter the geminabox server url when prompted)
1. `ssh production "bundle update awesome_site && sudo restart awesome_site"`

This is assuming you use `upstart` to manage your server process (probably my next blog topic).

Now, if you want more control, put the server code into git and manually set the version number in the gemfile. That way you can roll back to a version if you have a problem with a deploy. But, you could also reverse the commit, but bump the gem version and deploy as usual. This is a more honest representation of what happened and it means the HEAD of the code is accurate.

## Disclaimer

This is theoretical. The code is available at [ngauthier/awesome_site](http://github.com/ngauthier/awesome_site) and it does work. However I have never done this on a production application, so take care if you decide to go for it. I was just curious about what the process would be like.

Happy monday!
