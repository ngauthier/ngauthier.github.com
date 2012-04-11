---
layout: post
title: var self = lame
date: 2012-04-11
---

<script src="/javascripts/underscore-min.js" type='text/javascript'></script>

## var self = this

I see this in a lot of javascript code. The first thing it makes me think of is [Avdi Grimm](http://avdi.org)'s excellent talk [Confident Code](http://avdi.org/talks/confident-code-railsconf-2011/). I think that `var self = this` is an example of "timid code" in javascript. Avdi explains how timid code suffers from a "Lack of certainty" and it "lives in fear ... constantly second-guessing itself ... [and] imposes cognitive load on the reader". I highly recommend you read the slides or [watch the video](http://www.confreaks.com/videos/614-cascadiaruby2011-confident-code) even if you don't code ruby.

## Why?

Here's why `var self = this` is helpful: callback scope. Consider this code from [a JavascriptKata post](http://www.javascriptkata.com/2007/05/14/how-to-use-the-self-with-object-oriented-javascript-and-closures/):

<pre class='prettyprint'>
// Create a cat
function Cat() {
    this.theCatName = "Mistigri";
}
 
// The cat will meow later
Cat.prototype.meowLater = function() {
    // I create the variable self that refers to the this (the current object)
    var self = this;
 
    // I create a timeout that calls the self.meow function within an anonymous function
    /*** NOTE : You don’t always have to create an anonymous function it’s just that in
        this case, it is required ***/
    window.setTimeout(
        function() {
            self.meow();
        }
        , 1000);
}
// The cat meows
Cat.prototype.meow = function() {
    // I can use the this expression!!!
    alert(this.theCatName + " : meow!");
}
 
// I crate an object and call the meowLater() function
var theCat = new Cat();
theCat.meowLater();
</pre>
<a href='#meowlater'>Click here to run</a>
<script type='text/javascript'>
// Create a cat
function Cat() {
    this.theCatName = "Mistigri";
}
 
// The cat will meow later
Cat.prototype.meowLater = function() {
    // I create the variable self that refers to the this (the current object)
    var self = this;
 
    // I create a timeout that calls the self.meow function within an anonymous function
    /*** NOTE : You don’t always have to create an anonymous function it’s just that in
        this case, it is required ***/
    window.setTimeout(
        function() {
            self.meow();
        }
        , 1000);
}
// The cat meows
Cat.prototype.meow = function() {
    // I can use the this expression!!!
    alert(this.theCatName + " : meow!");
}
$('a[href="#meowlater"]').click(function() {
  var cat = new Cat();
  cat.meowLater();
});
</script>


## Fix #1: Using setTimeout's argument passing

The first way we can fix this use of timid scope passing is to use setTimeout's ability to pass arguments:

<pre class='prettyprint'>
function ApplyCat() {
  this.name = "Garbanzo"
}

ApplyCat.prototype.meowLater = function() {
  window.setTimeout(
    function(cat) {
      cat.meow()
    }, 1000, this
  )
}

ApplyCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}
</pre>
<a href='#meowlatertimeout'>Click here to run</a>
<script type='text/javascript'>
function TimeoutCat() {
  this.name = "Garbanzo"
}

TimeoutCat.prototype.meowLater = function() {
  window.setTimeout(
    function(cat) {
      cat.meow()
    }, 1000, this
  )
}

TimeoutCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}

$('a[href="#meowlatertimeout"]').click(function() {
  var cat = new TimeoutCat()
  cat.meowLater()
})
</script>

I'm passing `this` in as an argument for `setTimeout` to pass to the callback function, so that I have a reference to the cat.

So, this is better because instead of `var self = this` I'm passing `this` in as `cat`. This is equivalent to `var self = this` as far as scoping is concerned, and doesn't buy us too much. But, one thing it does to is that it's more explicit about *why* the scope is being passed, and *what* the scope is. But there's a better way.

## Fix #2: Use underscore.js

Why are we reinventing the wheel here? We've been binding scope since the dawn of time (or at least, the dawn of javascript). Why should we all repeat the same patterns over and over when smarter people have done it for us?


<pre class='prettyprint'>
function BindCat() {
  this.name = "Alfonso"
}

BindCat.prototype.meowLater = function() {
  window.setTimeout(_.bind(this.meow, this), 1000)
}

BindCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}
</pre>
<a href='#meowlaterbind'>Click here to run</a>
<script type='text/javascript'>
function BindCat() {
  this.name = "Alfonso"
}

BindCat.prototype.meowLater = function() {
  window.setTimeout(_.bind(this.meow, this), 1000)
}

BindCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}

$('a[href="#meowlaterbind"]').click(function() {
  var cat = new BindCat()
  cat.meowLater()
})
</script>

This is the best solution. For four reasons:

**First**, `_.bind(this.meow, this)` very clearly states that the objective of this code is to bind the scope of the function to the current object. `var self = this` says "I need to use this later" and then later on when you see `self` you remember that `self` is a scope shortcut to `this`. It's a minor cognitive load, but it's not worth dismissing.

**Second**, you're leaning on a well tested library like underscore to not mess things up. Whenever you can use someone else's shared library to do something, do it. Odds are they're covering edge cases you're not. For example, underscore's `bind` will use ECMAScript 5's native `bind` if it's available. By the way, underscore has a ton of other awesome methods you should be using.

**Third**, it's a one-liner. It's so succinct that I can put it right into the timeout call and it fits easily. `var self = this` is one extra line, plus the inline function definition causes three extra lines. Less is more.

**Fourth**, when you remove this line, it doesn't leave any other dangling lines of code. I've seen plenty of `var self = this` followed by a bunch of code that **doesn't have any callbacks in it**. There was no reason to declare `self`, yet it's used in place of `this` **out of fear**.

## Alternate Use of underscore

Another way you can use underscore for function binding is with `_.bindAll`:

<pre class='prettyprint'>
function BindAllCat() {
  _.bindAll(this);
  this.name = "Fred"
}

BindAllCat.prototype.meowLater = function() {
  window.setTimeout(this.meow, 1000)
}

BindAllCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}
</pre>
<a href='#meowlaterbindall'>Click here to run</a>
<script type='text/javascript'>
function BindAllCat() {
  _.bindAll(this);
  this.name = "Fred"
}

BindAllCat.prototype.meowLater = function() {
  window.setTimeout(this.meow, 1000)
}

BindAllCat.prototype.meow = function() {
  alert(this.name + " : meow!")
}

$('a[href="#meowlaterbindall"]').click(function() {
  var cat = new BindAllCat()
  cat.meowLater()
})
</script>

In the constructor, we use `_.bindAll`, which will bind every instance method to the instance. So no matter how you call the `meow` function, it will be bound to the cat. Now feel free to call your instance methods everywhere, and they will be scoped to the object, just like a real OO language.

## Conclusion

Please stop coding out of fear. Maybe you want to keep using `self` anyways because you think it reads better, but at least understand that there are many ways to accomplish proper scoping in javascript, and consider all of them when you run into these kinds of issues.

xoxo [@ngauthier](http://twitter.com/ngauthier)

## Pre-emptive comment responses

### It's less efficient

You're right. And C is even faster. You know what's the least efficient? Poorly readable and unmaintainable code.

### I don't have underscore, and I don't want to add more dependencies

It's 4kb. Suck it up. That's < 1ms on broadband. The collection extensions will change the way you enumerate, and underscore alone is worth it so you can write:

<pre class='prettyprint'>
var maxPrice = _(widgets).chain().map(function(widget) {
  return widget.price()
}).reduce(function(max, price) {
  return !max || price > max ? price : max
}).value();
</pre>

mmmm. map/reduce.

Also, every collection method automatically takes a context as an optional final parameter. So you can do:

<pre class='prettyprint'>
_(this.widgets).each(function(widget) {
  this.enable(widget);
}, this)
</pre>

`this` on the first two lines refers to the same object, because `this` is passed to `each` as the final parameter. IMO, `jQuery.on` should replace the `data` parameter with a `context` parameter. It would encourage more OO-style event coding. Backbone automatically binds all view event callbacks to the view, which is awesome.


## Solicitation for comments

The main reason I wrote this post is that a number of smart programmers I respect disagree with me. I would love to have a **constructive** and **positive** discussion on this topic. I never remove comments, so you can still hate on me, but everyone will know how lame you are on the internet.
