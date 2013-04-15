---
layout: post
title: Rails Controller Accessors
date: 2013-04-15
---

Recently, I've been reading [Practical Object-Oriented Design in Ruby](http://www.amazon.com/gp/product/0321721330?ie=UTF8&camp=213733&creative=393185&creativeASIN=0321721330&linkCode=shr&tag=nickga-20&qid=1366040757&sr=8-1) by [Sandi Metz](http://sandimetz.com/) (I highly recommend it!) and it got me thinking more about OO design in Rails. I realized that one of the patterns I've been using synced really well with the messages in the book, and I wanted to share it.

## Model Loading Filters

One of the most common Rails controller patterns is the before filter that fetches the record being accessed during member route actions. It looks like this:

<pre class="prettyprint">
class PostController < Application Controller
  before_filter :find_post, only: [:show, :edit, :update, :destroy]

  # actions redacted

  private

  def find_post
    @post = Post.find params[:id]
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "No Such Post"
    redirect_to posts_path
    return false
  end
end
</pre>

<pre class="prettyprint">
&lt;h1&gt;&lt;%= @post.title %&gt;&lt;/h1&gt;
</pre>

This makes `@post` available in the `show`, `edit`, `update`, and `destroy` actions, as well as making them available in the views.

However, there are a few problems with this implementation:

1. In views, you access the post as `@post` whereas in a partial, you have to either depend on `@post` being available, or you reference a local called `post`, which is inconsistent with `@post`.
2. The before filter has two responsibilities: finding the post and handling when there is no such post. Ideally this would be extracted into two methods each with one responsibility.
3. Instance variable copying is The Rails Way, but it's very different from The Ruby Way and Object Oriented best practices. In short, the view depends on the internals of the controller.

## Controller Accessors

Recently, I've been using Controller Accessors as an alternative. Here's what a Controller Accessor looks like:


<pre class='prettyprint'>
class PostController < Application Controller
  before_filter :ensure_post, only: [:show, :edit, :update, :destroy]

  # actions redacted

  private

  def post
    @post ||= Post.find_by_id params[:id]
  end
  helper_method :post

  def ensure_post
    redirect_to posts_path, alert: "No Such Post" unless post
  end
end
</pre>

<pre class="prettyprint">
&lt;h1&gt;&lt;%= post.title %&gt;&lt;/h1&gt;
</pre>

Here we've extracting the `post` finding to a separate accessor method with memoization. We also expose this accessor as a helper method, which is a great way to allow the view to access a controller's properties.

Note that in the view we access `post` and not `@post`. `@post` *is* still available, but accessing it via `post` is the polite way to do it, and it much more resilient.

We've also separated loading the post and ensuring that it is available by moving our filter to `ensure_post`.

Lastly, I've opted to use `find_by_id` instead of `find` because `find_by_id` returns nil instead of raising `ActiveRecord::RecordNotFound`, and a `nil` is easier to test for. Also, it wouldn't make sense for the `post` accessor to throw an exception (or to rescue it!) we'd rather have a `nil` to express that there is no such post.
