---
layout: post
title: Ruby on Rails on the Nexus 7
date: 2012-11-28
image: /images/nexus-7-rails.jpg
---

This evening I decided to put Ubuntu on my Nexus 7 to see how it performs and what packages are available on ARM. I'm happy to report that Ruby 1.9.3 (p194) and Rails 3.2.9 work perfectly (albeit slowly :-D).

<img src="/images/nexus-7-rails.jpg" alt="Nexus 7 Running Rails">

## Step 1: Ubuntu

I followed [Ubuntu's steps for installation](https://wiki.ubuntu.com/Nexus7/Installation) and it worked fine. There was an odd issue connecting via ssh, but I think it was my router. I had to ssh out of the tablet to my desktop before the desktop could ssh to the tablet. `iptables` was empty on both. Dunno what was up.

## Step 2: Ruby

I followed [my own ubuntu setup instructions](/2012/01/simple-ruby-on-ubuntu.html), except I substituted `libsqlite3-dev` for the postgresql packages.

## Step 3: Rails

I ran `gem install bundler` and `gem install rails`, took a minute or two, but it worked.

## Step 4: A Blog!

Of course I had to make a blog, that's the Hello World of Rails! I simply used `rails g scaffold Post title:string body:text` then `rake db:migrate` and `rails server`, then wrote my post.

Honestly I was very disappointed at how easy it all was. I was looking for a challenge :-D

[@ngauthier](http://twitter.com/ngauthier)
