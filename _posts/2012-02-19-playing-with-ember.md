---
layout: post
title: Playing with Ember.js
date: 2012-02-19
---

Today I played around with [Ember.js](http://emberjs.com). I wanted to make my own Pomodoro timer, and I figured it would be a good way to try it out.

One of the reasons I'm really excited about Ember is that its goal is to **cut down on boilerplate code** especially in regards to keeping views up to date.

I'd like to mention that I have no idea whether or not I really did this right. Ember's docs are in a state of flux as the framework has yet to hit 1.0 and so much is changing. Also, I was particularly confused by the source code, as it seems to be in packages that don't always have a clear hierarchy. For example, the core `Ember.Application` class is under `packages/ember-views/lib/system/application.js`. So, I did dig around a while and I hope I am pretty close to the mark.

First up, **Ember's HTML**

<pre class='prettyprint'>
&lt;script type="text/x-handlebars" data-template-name='timer'&gt;
  &lt;div class='timeleft'&gt;{{ "{{" }}timeLeft}}&lt;/div&gt;
  &lt;a href="#" class='btn btn-large btn-primary' {{ "{{" }}action "pomodoro"}}   &gt;Pomodoro&lt;/a&gt;
  &lt;a href="#" class='btn btn-large'             {{ "{{" }}action "shortBreak"}} &gt;Short Break&lt;/a&gt;
  &lt;a href="#" class='btn btn-large'             {{ "{{" }}action "longBreak"}}  &gt;Long Break&lt;/a&gt;
  &lt;a href="#" class='btn btn-large btn-danger'  {{ "{{" }}action "stop"}}       &gt;Stop&lt;/a&gt;
&lt;/script&gt;
&lt;h1&gt;Pomodoro&lt;/h1&gt;
&lt;div id='timer'&gt;&lt;/div&gt;
</pre>

We define a reusable template as a handlebars script tag and give it a name. Then lower down is a `#timer` div that we'll bind to. This is not the standard Ember way of placing a template. In the examples, you'll see:


<pre class='prettyprint'>
&lt;h1&gt;Pomodoro&lt;/h1&gt;
&lt;script type="text/x-handlebars"&gt;
  {{ "{{" }}view Todos.MainView}}
&lt;/script&gt;
</pre>

However this really rubbed me the wrong way because I hate global variables (`Todos.MainView`). This template itself is kind of a global since it's directly in the dom. I prefer to give the template a global variable name (`data-template-name`) and have the view reference it.

My other alternative would be to define the template in the code, but that would take it farther from the html it's being used in. I would like feedback and advice on this, please!

Next, is **Ember's Timer** (note: all the JS is in a jQuery onReady closure, hence `var` not `window.`, because I hate globals):

<pre class='prettyprint'>
var Pomodoro = Em.Application.create();

var timer = Ember.Object.create({
  timeLeft: "25:00",
  totalTime: 25*60*1000,
  
  start: function(time) {
    var _this = this;
    this.reset(time);
    this._startedAt = new Date();
    this._intervalId = setInterval(function() { _this.updateTimeLeft.apply(_this); }, 100);
  },
  
  reset: function(time) {
    clearInterval(this._intervalId);
    if (time) {
      this.set('totalTime', time*60*1000);
    }
    this.set('timeLeft', msToString(this.get('totalTime')));
  },
  
  updateTimeLeft: function() {
    var now = new Date();
    var diff = now - this._startedAt;
    this.set('timeLeft', msToString(this.get('totalTime') - diff));
  }
});
</pre>

We're using Ember's Object base class, and we are making use of the getters and setters, which let us bind in the view. Here's **Ember's View**:

<pre class='prettyprint'>
Ember.View.create({
  templateName: 'timer',
  timer: timer,
  timeLeftBinding: 'timer.timeLeft',

  pomodoro: function(){
    this.timer.start(25);
  },
  shortBreak: function() {
    this.timer.start(5);
  },
  longBreak: function() {
    this.timer.start(15);
  },
  stop: function() {
    this.timer.reset();
  }
}).appendTo('#timer');
</pre>

We're binding the View to the template we created, we're setting a local var `timer` to the `timer` var we instantiated when making our timer. Then we bind the view's `timeLeft` attribute to the `timer`'s `timeLeft` attribute. This will automatically update the dom, when the model's attribute changes. The special naming `timeLeftBinding` means that it's a binding.

The next four methods are triggered by clicking the template links with the actions of the same name. So if you look at the template, each link has an action, and that action is a function to call on the view.

I looked for a controller to use, since the view is really being both a controller and a view here (actually, the model does some of the view work too, as it formats its timestamp). However, the only Ember controller I could find was an ArrayController, which is actually just an Array with some event bindings. So, I guess they don't have the C of MVC yet.

All in all, there is not a lot of boilerplate code here, so nice job guys!

Now, I can't leave it there, because I've done a ton of work with Backbone.js, and it seems like Ember is calling out Backbone and others like it "[obvious low-level event-driven abstractions](http://emberjs.com)."

So, I implemented the same timer in Backbone to see how much boilerplate I had to write:

**Backbone's HTML**:

<pre class='prettyprint'>
&lt;h1&gt;Pomodoro&lt;/h1&gt;
&lt;div id='backbone-timer'&gt;
  &lt;div class='timeleft'&gt;&lt;/div&gt;
  &lt;a href="#" class='btn btn-large btn-primary pomodoro'   &gt;Pomodoro&lt;/a&gt;
  &lt;a href="#" class='btn btn-large             short-break'&gt;Short Break&lt;/a&gt;
  &lt;a href="#" class='btn btn-large             long-break' &gt;Long Break&lt;/a&gt;
  &lt;a href="#" class='btn btn-large btn-danger  stop'       &gt;Stop&lt;/a&gt;
&lt;/div&gt;
</pre>

Unlike Ember, this is direct html I am writing right in the dom, not script tags. If there's a way to bind Ember to existing elements, let me know!

Next, we have **Backbone's Timer**:


<pre class='prettyprint'>
var timer = new (Backbone.Model.extend({
  defaults: {
    timeLeft: "25:00",
    totalTime: 25*60*1000
  },

  start: function(time) {
    this.reset(time);
    this._startedAt = new Date();
    this._intervalId = setInterval(_.bind(this.updateTimeLeft, this), 100);
  },

  reset: function(time) {
    clearInterval(this._intervalId);
    if (time) {
      this.set('totalTime', time*60*1000);
    }
    this.set('timeLeft', msToString(this.get('totalTime')));
  },
  
  updateTimeLeft: function() {
    var now = new Date();
    var diff = now - this._startedAt;
    this.set('timeLeft', msToString(this.get('totalTime') - diff));
  }
}))();
</pre>

The first difference is we don't have to init an application, because Backbone is a library, not a framework. The second difference is that Backbone has a forced separation between get/set attributes and object attributes. Thus there is a `defaults` hash for the get/set attributes, as opposed to declaring them on the object. I find this to be more declarative than Ember's syntax.

The next difference is that since underscore is a dependency, I used `_.bind` for the timer. But we could do this in Ember too, if we brought in underscore.

Other than that, these objects are almost exactly the same.

Let's look at **Backbone's View**:

<pre class='prettyprint'>
new (Backbone.View.extend({
  events: {
    'click a.pomodoro'   : 'pomodoro',
    'click a.short-break': 'shortBreak',
    'click a.long-break' : 'longBreak',
    'click a.stop'       : 'stop'
  },

  initialize: function() {
    this.model.bind('change:timeLeft', this.updateTimeLeft, this);
  },

  render: function() {
    this.updateTimeLeft();
    return this;
  },

  updateTimeLeft: function() {
    this.$('.timeleft').text(this.model.get('timeLeft'));
  },

  pomodoro: function() {
    this.model.start(25);
  },

  shortBreak: function() {
    this.model.start(5);
  },

  longBreak: function() {
    this.model.start(15);
  },

  stop: function() {
    this.model.reset();
  }
}))({el: $('#backbone-timer'), model: timer}).render();
</pre>

Now we're seeing some difference! In Backbone, we have to bind all the link actions ourselves on the view instead of on the template. This is definitely more legwork on the View's part, but remember is means that template could drive different views with different behavior, because the behavior is defined in the view, not the template. Personally, I like to keep code out of my templates.

Next, we have to manually bind the `change` event on the model to a method that updates the text of that dom element. Definitely boilerplate. Ember does this by automatically creating wrapper divs like `<div id="ember150" class="ember-view">` that wrap your templated attributes and auto-updates them.

After that, the methods are the same. Then when we initialize we give it a dom element to bind to, and we have to manually tell it to render the first time.

At this point, I'd like to pull out a refactoring from [Recipes with Backbone](http://recipeswithbackbone.com) from the Fill-In Views chapter. Check this out:

<pre class='prettyprint'>
/* EDIT: updated to use #constructor. Thanks Tim Branyen! */
Backbone.BoundView = Backbone.View.extend({
  constructor: function(options) {
    Backbone.View.apply(this, arguments);

    this.model.bind('change', this.updateBoundAttributes, this);
    this._oldRender = this.render;
    this.render = function() { this._oldRender(); this.updateBoundAttributes(); };
  },

  updateBoundAttributes: function() {
    _(this.bindings).each( function(value, key) {
      this.$(key).html(this.model.get(value))
    }, this);
  }
});
</pre>

This `Backbone.BoundView` is a subclass of `Backbone.View` and it uses a `bindings` object to automatically update model attributes on change. That means we can simplify our view to this:

<pre class='prettyprint'>
  new (Backbone.BoundView.extend({
    events: {
      'click a.pomodoro'   : 'pomodoro',
      'click a.short-break': 'shortBreak',
      'click a.long-break' : 'longBreak',
      'click a.stop'       : 'stop'
    },

    bindings: {
      '.timeleft': 'timeLeft'
    },

    pomodoro: function() {
      this.model.start(25);
    },

    shortBreak: function() {
      this.model.start(5);
    },

    longBreak: function() {
      this.model.start(15);
    },

    stop: function() {
      this.model.reset();
    }
  }))({el: $('#backbone-timer-2'), model: timer}).render();
});
</pre>

We still have the event bindings, but now all the model updating code has been reduced to a `bindings` object that maps dom classes to model attributes. Much better!


All-in-all, I have to say I'm not super impressed with Ember's view and model bindings. But, I could certainly not be taking full advantage of them at this time. I did experiment with computed attributes, and those were neat. I do like the idea that functions can behave as properties as well. Also, we didn't get into any of Ember's other awesome features like states.

I was planning on making my Pomodoro timer in Ember, but after having some issues with the docs and the source, and not finding many satisfactory examples, I'm going to stick with Backbone for now. But you can be sure when Ember hits 1.0 I'm going to check it out!
