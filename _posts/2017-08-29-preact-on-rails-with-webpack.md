---
layout: post
title: Preact on Rails with Webpack
date: 2017-08-29
---

I needed to brush up my front-end skills, since I've been in Gopherland for a couple years now,
so I decided to write a few tutorials about using Rails with modern front-end frameworks. I'm
learning this as I go, so please feel free to comment or message me on Twitter if you have some
tips about the setup.

In this article, we're going to walk through how to set up Rails 5.1 with Webpack to use Preact
as a front-end framework. Rails 5.1 is the first version of Rails to support Webpack as part of
the application scaffolding process, which makes it easy (well ... eas*ier*) to get started with.

[Preact](https://preactjs.com/) is an alternate implementation of React using native dom features
and with a focus on being small and light and lower in dependencies. I like the idea of Preact
because it seems more approachable because of its smaller source code. I know I can just dig
through it if I encounter something unexpected. I mean, [look at its source code](https://unpkg.com/preact@8.2.5)
(seriously, open that link, that's Preact without ES6 and JSX).

## Prerequisites

In order to run through this tutorial, you'll need:

* Ruby >2.2.2 (I'm using 2.4.0)
* Rails >5.1 (I'm using 5.1.4.rc1)
* NodeJS >6 (I'm using 6.11.2)
* Yarn >0.20.1 (I'm using 0.27.5)

## Creating a new Rails App with Webpack

The first thing we need to do is make a new Rails app with Webpack. We're also going to remove
all the things we won't need, since we'll be using Preact. Here's how we set up our application:

<pre class='prettyprint bash'>
rails new hello \
  --skip-action-cable \
  --skip-sprockets \
  --skip-coffee \
  --skip-javascript \
  --skip-turbolinks \
  --webpack
</pre>

We're going to skip action cable, sprockets, coffeescript, rails javascript helpers, and turbolinks. And we're going to turn on Webpack.

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

## Trimming the Fat

Webpacker's install is great because it brings in everything you might need. But, we can trim down a bunch of its
dependencies since we will just be using Preact. First off, lets remove some vestigal asset pipeline folders:

<pre class='prettyprint bash'>
rm -rf app/assets/ lib/assets/
</pre>

Also, **edit app/views/layouts/application.html.erb** and remove the stylesheet tag and replace it with a
webpack tag:

<pre class='prettyprint html'>
&lt;!DOCTYPE html&gt;
&lt;html&gt;
  &lt;head&gt;
    &lt;title&gt;Hello&lt;/title&gt;
    &lt;%= csrf_meta_tags %&gt;

    &lt;%= javascript_pack_tag 'application' %&gt;
  &lt;/head&gt;

  &lt;body&gt;
    &lt;%= yield %&gt;
  &lt;/body&gt;
&lt;/html&gt;
</pre>

Next, let's check out our `package.json`:

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
    "webpack-dev-server": "^2.7.1"
  }
}
</pre>

Wow, that's a lot of stuff! We can remove the coffeescript packages since we'll be using ES6:

<pre class='prettyprint bash'>
yarn remove coffee-loader coffee-script
</pre>

We can also remove the rails-erb-loader since we won't be using any erb templates in our javascript:

<pre class='prettyprint bash'>
yarn remove rails-erb-loader
</pre>

Now we can remove those loaders from webpack:

<pre class='prettyprint bash'>
rm config/webpack/loaders/coffee.js config/webpack/loaders/erb.js
</pre>

And in `config/webpacker.yml` we can remove the following extensions:

* .coffee
* .erb
* .ts
* .vue

Just to make sure you didn't break anything, you can run:

<pre class='prettyprint bash'>
./bin/webpack
</pre>

to bundle up your assets. Mine looks like this:

<pre class='prettyprint'>
Hash: 77d3b57fb7806bb9009c
Version: webpack 3.5.5
Time: 262ms
                              Asset      Size  Chunks             Chunk Names
application-8f8bdd9f4ff51391ec46.js   4.47 kB       0  [emitted]  application
                      manifest.json  68 bytes          [emitted]
   [0] ./app/javascript/packs/application.js 515 bytes {0} [built]
</pre>

## Installing Preact

Installing Preact is as easy as:

<pre class='prettyprint bash'>
$ yarn add preact
yarn add v0.27.5
[1/4] Resolving packages...
[2/4] Fetching packages...
[3/4] Linking dependencies...
[4/4] Building fresh packages...
success Saved lockfile.
success Saved 1 new dependency.
└─ preact@8.2.5
Done in 3.96s.
</pre>

Of course, that doesn't do anything to our app, because we're not using Preact anywhere yet.
In order to try it out, we're going to need a page to work with in our app. I'm going to be
lazy and just add a view to the application controller.

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

Now we can run `rails server` and it should just be a blank screen, but in the console, we should see:

<pre class='prettyprint'>
Hello World from Webpacker
</pre>

Yay! Just for a sanity check, edit `app/javascript/packs/application.js` and edit the message and refresh your
browser and you should see a new message (because Rails should recompile your assets for you with webpacker).

Additionally, we're going to use JSX, so we need to install the babel JSX transformer:

<pre class='prettyprint bash'>
yarn add babel-plugin-transform-react-jsx
</pre>

And in order to map this transformer to Preact's `h` method, add this line inside `plugins` in your `.babelrc`:

<pre class='prettyprint json'>
["transform-react-jsx", { "pragma":"h" }]
</pre>

## Preact Hello World

Now it's time to actually use Preact (finally, whew). Edit `app/javascript/packs/application.js` and add this line:

<pre class='prettyprint js'>
import('hello.js')
</pre>

That's going to import `app/javascript/hello.js` (which we are about to write) into your app.

Here's what we put into `app/javascript/hello.js` (which is straight from [Preact's tutorial](https://preactjs.com/guide/getting-started)):

<pre class='prettyprint js'>
import { h, render, Component } from 'preact';

render((
    &lt;div id="foo"&gt;
        &lt;span&gt;Hello, world!&lt;/span&gt;
        &lt;button onClick={ e =&gt; alert("hi!") }&gt;Click Me&lt;/button&gt;
    &lt;/div&gt;
), document.body);
</pre>

Now, we should be able to refresh our site, and see the Preact demo. Click the button and it says "Hi!". We did it.

## Wrapping up

One of the things I was interested in is page weight. When running our app in dev mode, I saw two JS files, one is
application.js, which contains a bunch of webpack code for dynamically loading all our JS files separately. This is
great in development because we only have to rebuild what we change. So that's why there's a second "chunk" file
also being loaded.

Doing a production asset build is as easy as:

<pre class='prettyprint bash'>
RAILS_ENV=production ./bin/webpack
</pre>

Then run our dev server again:

<pre class='prettyprint bash'>
rails server
</pre>

As long as you don't touch any JS files our production built JS files are used. From here I was able to see that
our application.js was just shy of 1kB, and our chunk with hello.js and preact in it are 3.7KB. Great! So we're
under 5KB, which is awesome.

I'm not sure if it's possible to have just one application.js file (no chunks) so if you know how, let me know!
