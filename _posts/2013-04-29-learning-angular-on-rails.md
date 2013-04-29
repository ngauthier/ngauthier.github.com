---
layout: post
title: Learning Angular on Rails
date: 2013-04-29
---

Last night I had the best idea for a JavaScript framework. It was going to use the dom with data attributes in a totally unobtrusive way. It would have global repositories for remote data, do caching, and attach controllers to the dom automatically.

This morning, I realized that's pretty much how Angular.js rolls, so I decided to learn the basics.

## 1. Setup Rails

First, I setup a Rails app as the back-end. I used Rails 4.0.0.beta1. I also decided that since Angular does so much heavy `data-attr` (actually `ng-attr`) work in the view, I wanted something nicer than erb, so I added Slim for templating. Also, I like CoffeeScript, so I stuck with that.

I setup a Post model and controller. Angular behaved a little differently, so the controller looks a little different:

<pre class='prettyprint'>
class PostsController < ApplicationController
  include AngularController

  def index
    @posts = Post.all
    respond_with @posts
  end

  def create
    respond_with Post.create!(params.permit(:title, :body))
  end

  def destroy
    Post.destroy(params[:id])
    head :ok
  end
end
</pre>

I'm using `respond_with` to send the html template on index or json for the index, depending on the request. I also use it in the `create` action because that will send down json automatically, and I find it cleaner than `render json: post`.

I created a Concern called `AngularController` that abstracted the necessary json massaging that Angular needed:

<pre class="prettyprint">
module AngularController
  extend ActiveSupport::Concern

  included do
    respond_to :html, :json
    around_action :without_root_in_json
  end

  def without_root_in_json
    ActiveRecord::Base.include_root_in_json = false
    yield
    ActiveRecord::Base.include_root_in_json = true
  end
end
</pre>

It adds the `respond_to` to work with `respond_with`. It also sets up an `around_action` to temporarily remove the root of json responses. I thought this was a cool way to do it, instead of doing it globally.

Now the Rails app is setup. I actually set it up while learning angular, but I thought I'd present it here first for simplicity's sake.

# 2. Angular Time!

I grabbed `angular.js` and also `angular-resource.js` (RESTful requests) and dropped them into `vendor/assets/javascripts`, as well as loading up Twitter Bootstrap to make it look Not Terrible&#0153;.

In `app/views/index.html.slim` I added:

<pre class='prettyprint'>
- content_for :ng_app, "blang"

.container
  .hero-unit
    h1 Posts
    p Driven by Angular.js

  div ng-controller="PostCtrl"
    .post ng-repeat="post in posts"
      h2 
        | {{ "{{" }} post.title }}
        button.btn.btn-danger.btn-small.pull-right ng-click="delete($index)" &times;
      | {{ "{{" }} post.body }}

    form ng-submit="add()" action=""
      fieldset
        legend Create Post
        
        input    ng-model="post.title" type="text" id="post-title" placeholder="Title"
        br
        textarea ng-model="post.body" placeholder="Content" rows="4" columns="40"
        br

        input.btn.btn-primary type="submit" value="Create"
</pre>

I use `content_for :ng_app` in the layout to render Angular's `ng-app="blang"` so that it boots up. The page is driven by the `PostCtrl` controller, and it loops over all the `posts` in `PostCtrl`. It outputs their title and body, along with a delete button.

Below, there's a form that hits the `add()` method of `PostCtrl` feeding it the `title` and `body` of the `post` that we're creating.

Here's my `posts.coffee`:

<pre class='prettyprint'>
# Set up the module
window.Blang = angular.module("blang", ["ngResource"])

Blang.config ["$httpProvider", ($httpProvider) ->
  # Inject the CSRF token
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = document.getElementsByName("csrf-token")[0].content
  # By default, angular sends "application/json, text/plain, */*" which rails
  # sees and focuses on the */* and sends html :-(
  $httpProvider.defaults.headers.common['Accept'] = "application/json"
]


# Here's our Post resource for interacting with the server
Blang.factory "Post", ($resource) -> $resource "/posts/:id", id: "@id"

# Post Controller
Blang.controller "PostCtrl", ($scope, Post) ->
  # This is the post we use for the form
  $scope.post = new Post()

  # Posts for the list
  $scope.posts = Post.query()

  # Add a new post
  $scope.add = ->
    # add to the local array and also save to the server
    $scope.posts.push Post.save title: $scope.post.title, body: $scope.post.body
    # reset the post for the form
    $scope.post = new Post()

  # Delete a post
  $scope.delete = ($index) ->
    # Yay, UX!
    if confirm("Are you sure you want to delete this post?")
      # Remove from the server
      $scope.posts[$index].$delete()
      # Remove from the local array
      $scope.posts.splice($index, 1)
</pre>

All in all, it wasn't much code, but it was very difficult to figure out what I was supposed to be doing. But that's all part of learning a new framework. Here are a bunch of gotchas I ran into:

1. Providing the `id: "@id"` mapping in the resource url. Without this, it doesn't automatically fill in `:id` with the model's id.
2. I had to keep the local array of posts in sync with the server, pushing to it and splicing from it as I added and removed items.
3. Using `$scope` everywhere to expose methods in the view took me a bit to realize
4. I couldn't delete a post by calling a method on the instance, because it wouldn't remove it from the main collection

All in all, I found Angular to be pretty comprehensive when it came to the view binding and automatic dom reflection of underlying state. However I found its server synchronizing abilities to be lacking. Why is `angular-resource.js` a separate library anyways?

I think it would be really interesting to use Angular.js as a declarative templating and view language, but then maybe drop to backbone for models and controllers. I could expose `collection.models` to the scope, and it could watch that array. Then it should properly add and remove models from a collection.

I'm really curious to hear how experienced users of Angular communicate with a server and keep their data in sync.

If you'd like to mess around with the code, [I put the application on GitHub](http://github.com/ngauthier/angular-on-rails).
