---
layout: post
title: Simple ruby setup on ubuntu
date: 2012-01-30
---

Today I setup a new development machine. My preferred OS is [Xubuntu](http://xubuntu.com), which is Ubuntu + XFCE (a light window manager). In the past I've used RVM and have been happy with it, except for one thing: compiling.

I used to use Gentoo, which is a linux distribution in which all software is installed by downloading the source and compiling. This is a brutal and intense introduction to linux, and I learned a hell of a lot using Gentoo in college. However, I feel like I've paid my dues in linux boot camp and now I want to simply install binary packages and have a ruby setup lightning-quick.

So, here were my steps to get ruby (and postgres) setup:

## Ruby

Install ruby, rubygems, a few dependencies and postgres: <a href="apt:libxslt1-dev,libxml2-dev,build-essential,g++,ruby1.9.1-dev,postgresql,libpq-dev">libxslt1-dev libxml2-dev build-essential g++ ruby1.9.1-dev postgresql libpq-dev</a>.

## Bundler and gem-scoping

The only remaining issue is how to manage sets of gems between projects. I chose to do something here which leverages one of bundler's great features to achieve a halfway gemset solution. It is not exclusive of gems installed globally, but it gives priority to local binaries over global ones.

In your .bashrc (or whatever shell init script):

<pre class='prettyprint'>
alias bundle-bootstrap="bundle install --binstubs=.bundle/bin --path=.bundle/gems"
export GEM_HOME=$HOME/.gems
export PATH=.bundle/bin:$GEM_HOME/bin:$PATH
</pre>

The bundler alias will put binstubs (shell scripts that run a gem's binary) into the current directory's `.bundle/bin`. It also says to store the gem sources in `.bundle/gems`. This means that as soon as you leave this directory, it's like those gems aren't even installed!

The second line puts the current directory's `.bundle/bin` as the highest priority for finding binaries, followed by my home directory's gems binary folder. This means that local gem binaries take precedent. That means **no more bundle exec**.

The third line sets up my gem home so if I just run `gem install` they go to my home. This is where I put bundler, jekyll, heroku, etc.

## Setting up a project

So, when I setup a new project, it looks like:

<pre class='prettyprint'>
git clone git@github.com:user/repo.git
cd repo
bundle-bootstrap
</pre>

Now everything is installed and setup. Binaries are available but don't contaminate any other projects.

Hope this helps all my fellow linux rubyists on having a fast and clean ruby install!

xoxo [@ngauthier](http://twitter.com/ngauthier)

P.S.: if you need ruby 1.8.7, check out rbenv, which is now in APT as of 12.04. You can install ruby 1.8 from APT then use rbenv to switch rubies. I haven't used it myself but it seems to be what people prefer.
