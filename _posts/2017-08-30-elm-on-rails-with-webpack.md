---
layout: post
title: Elm on Rails with Webpack
date: 2017-08-30
---

Continuing from [part 1: Preact on Rails with Webpack]({% post_url 2017-08-29-preact-on-rails-with-webpack %}), today we're going to look at how to set up Elm in front of Rails using Rails 5.1's new webpack scaffolding.

Elm is a very interesting language to me for a couple of reasons. First, I've been doing Go for a few years now, and I've found its simplicity (one way to do things), static type system, and auto formatting to be very relieving. As a programmer, I have not had to think as hard about the details of solving a problem, and instead I can just go right to solving it. Elm seems to share some of these ideas too.

Elm has a formatter, like Go, so code always looks the same (and you don't have to worry about typing it perfectly). It has a static type system that makes writing and refactoring code easier because it surfaces errors faster (at compile time) letting you skip right to behavioral errors in your code (through tests of course!) Elm also promises zero runtime errors, which sounds incredible!

In my opinion, the tradeoff Elm asks in exchange for these features is that it's an additional language to put on your stack, which comes with it's own overhead of learning the language and maintaining the tooling as part of your build process. Additionally, Elm takes additional effort to integrate with existing JavaScript through its ports system. The ports system makes sense to me, as creating a safe barrier into the "error-free" world of Elm. But it means we're going to have some overhead.

Luckily, while Elm has its own binary tooling, they've made it distributable through npm and buildable through webpack, meaning that you can pretend like it's another JavaScript framework (I mean, I guess it kind of is!) On top of that, it is a first-class citizen in the new Rails 5.1 webpack scaffolding, meaning Rails can set up Elm for us.

Let's get started.

## Prerequisites

Similar to Part 1, you'll need this before we continue:

* Ruby >2.2.2 (I'm using 2.4.0)
* Rails >5.1 (I'm using 5.1.4.rc1)
* NodeJS >6 (I'm using 6.11.2)
* Yarn >0.20.1 (I'm using 0.27.5)

## Creating a new Rails App with Webpack and Elm

Slightly different from part 1, we can use Rails's Elm webpack scaffold to give us a jumpstart:

<pre class='prettyprint bash'>
rails new hello \
  --skip-action-cable \
  --skip-sprockets \
  --skip-coffee \
  --skip-javascript \
  --skip-turbolinks \
  --webpack=elm
</pre>

Note the last line, where instead of just `--webpack` to setup the webpack pipeline, we can say `--webpack=elm` and Rails will add Elm as a dependency and set it up with webpack to detect and package Elm files.

### Using Webpacker @ master

**Heads up! There's currently a bug with automatic compilation so we're going to use Webpack @ master**. Once a release > 2.0.0 of `rails/webpacker` is released, you should be able to use that instead of this step.

Edit our Gemfile, and modify the `webpacker` line to use master from GitHub:

<pre class='prettyprint ruby'>
gem 'webpacker', github: 'rails/webpacker'
</pre>

Then update it:

<pre class='prettyprint bash'>
bundle update webpacker
</pre>

As of the writing of this post, I'm on `master@691389f`.

Finally, reinstall webpacker:

<pre class='prettyprint bash'>
rails webpacker:install
</pre>

(you can answer `a` to allow all updates)

## Hello Elm

Since Webpacker sets Elm up for us automatically, all we have to do is edit `app/views/layouts/application.html.erb` and remove the stylesheet tag and replace it with a webpack tag:

<pre class='prettyprint html'>
&lt;!DOCTYPE html&gt;
&lt;html&gt;
  &lt;head&gt;
    &lt;title&gt;Hello&lt;/title&gt;
    &lt;%= csrf_meta_tags %&gt;

    &lt;%= javascript_pack_tag 'hello_elm' %&gt;
  &lt;/head&gt;

  &lt;body&gt;
    &lt;%= yield %&gt;
  &lt;/body&gt;
&lt;/html&gt;
</pre>

The Elm Webpacker install automatically creates a `hello_elm` pack for us to start with as a "hello world" example. In order to see this example though, we need a page in our app. We're going to be lazy and just add a view to the application controller:

In `config/routes.rb`:

<pre class='prettyprint ruby'>
Rails.application.routes.draw do
  root to: 'application#index'
end
</pre>

<pre class='prettyprint'>
$ mkdir app/views/application
$ touch app/views/application/index.html.erb
</pre>

Now run `rails server` open up your app, and it should say "Hello Elm!". Pretty easy, huh!

## Trimming the Fat

Webpack is great because it sets up everything we need to get started, but when using Elm it brings in a lot more than we need. First, we can start by removing old asset pipeline paths:

<pre class='prettyprint'>
rm -rf app/assets lib/assets
</pre>

Next, let's open up `package.json`:

<pre class='prettyprint json'>
{
  "name": "hello",
  "private": true,
  "dependencies": {
    "autoprefixer": "^7.1.3",
    "babel-core": "^6.26.0",
    "babel-loader": "7.x",
    "babel-plugin-syntax-dynamic-import": "^6.18.0",
    "babel-plugin-transform-class-properties": "^6.24.1",
    "babel-plugin-transform-object-rest-spread": "^6.26.0",
    "babel-polyfill": "^6.26.0",
    "babel-preset-env": "^1.6.0",
    "coffee-loader": "^0.8.0",
    "coffee-script": "^1.12.7",
    "compression-webpack-plugin": "^1.0.0",
    "css-loader": "^0.28.5",
    "elm": "^0.18.0",
    "elm-webpack-loader": "^4.3.1",
    "extract-text-webpack-plugin": "^3.0.0",
    "file-loader": "^0.11.2",
    "glob": "^7.1.2",
    "js-yaml": "^3.9.1",
    "node-sass": "^4.5.3",
    "path-complete-extname": "^0.1.0",
    "postcss-cssnext": "^3.0.2",
    "postcss-loader": "^2.0.6",
    "postcss-smart-import": "^0.7.5",
    "precss": "^2.0.0",
    "rails-erb-loader": "^5.2.1",
    "resolve-url-loader": "^2.1.0",
    "sass-loader": "^6.0.6",
    "style-loader": "^0.18.2",
    "webpack": "^3.5.5",
    "webpack-manifest-plugin": "^1.3.1",
    "webpack-merge": "^4.1.0"
  },
  "devDependencies": {
    "elm-hot-loader": "^0.5.4",
    "webpack-dev-server": "^2.7.1"
  }
}
</pre>

Because we're not going to use any JavaScript except for some vanilla Elm bindings, we can remove a few packages:

<pre class='prettyprint'>
yarn remove \
  coffee-loader \
  coffee-script \
  rails-erb-loader
</pre>

And we can also remove Webpack's loaders:

<pre class='prettyprint'>
rm \
  config/webpack/loaders/coffee.js \
  config/webpack/loaders/erb.js
</pre>

And we can also remove the following extensions from `config/webpacker.yml`:

* .coffee
* .erb
* .jsx
* .ts
* .vue

## Wrapping Up

Similar to part 1, I wanted to look at Elm's page weight. I was sure it would be higher than Preact because we're adding an entire language, but I was pleasantly surprised. To see production weight, compile the pack in production mode:

<pre class='prettyprint bash'>
RAILS_ENV=production ./bin/webpack
</pre>

Then run the server again:

<pre class='prettyprint bash'>
rails server
</pre>

Now our hello-elm JavaScript file weighs just 20KB. This was definitely less than I expected.

I was also surprised at how easy setting up Elm was. In fact, I was disappointed because I wanted to be challenged to actually write hello world in Elm on my own. So, I guess that means I'll have to write a follow up post!
