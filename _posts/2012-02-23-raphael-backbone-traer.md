---
layout: post
title: Raphael.js + Backbone.js + Traer.js
date: 2012-02-23
---

[Raphael.js](http://raphaeljs.com/) is a cool vector graphic drawing library for javascript. It uses SVG (VML on IE) to draw just about anything, and provides lots of easy helper methods. The coolest thing about SVG is that since it's XML it can be inserted directly into the dom, so every element has its own dom node.

One of my favorite things about [Backbone.js](http://documentcloud.github.com/backbone/) is that the only assumption it makes about Views is that they will have a dom element, `el`. So, I thought it would be really cool if you used a Backbone.js view to render Raphael objects.

Now, to make this extra awesome, I wanted to use the physics engine [Traer.js](http://code.google.com/p/traer-js/).

This was the result:

## Video

<div><iframe class='youtube' src="http://www.youtube.com/embed/S8n8P5fk5YY" frameborder="0" allowfullscreen></iframe></div>

## Demo

<iframe src="/demo/backbone-raphael-traer.html" frameborder="0" class='youtube' scrolling="no"></iframe>

[Visit demo page](/demo/backbone-raphael-traer.html)

There are four levels here:

1. Particle: managed by Traer
2. Model: Backbone model wrapping the particle
3. Element: svg element managed by Raphael
4. View: Backbone view wrapping the model and the element

## Step 1. Modding the physics engine

This first thing I had to do was make two small changes to Traer:

<pre class='prettyprint'>
function Particle(mass) {
  this.position = new Vector();
  this.velocity = new Vector();
  this.force = new Vector();
  this.mass = mass;
  this.fixed = false;
  this.age = 0;
  this.dead = false;
  /* Attach Backbone's events to particles */
  _.extend(this, Backbone.Events);
}
</pre>

<pre class='prettyprint'>
RungeKuttaIntegrator.prototype.step = function (deltaT) {
  /* lots of physics stuff redacted */

  /* Change the conditional for skipping fixed nodes so that the
   * following runs for all particles after they've been computed:
   */
  p.trigger('change'); // p is the particle
</pre>

Now, particles will fire a `change` event after a physics tick.

## Step 2. Backbone Model based on Traer

<pre class='prettyprint'>
Exobrain.Node = Backbone.Model.extend({
  // expects a particle and a size parameter
  initialize: function(attributes) {
    // when the particle changes, we fire a change
    this.get('particle').on('change', function() {
      this.trigger('change'); 
    }, this);
    // keep track of children
    this.children = new Exobrain.NodeList();
  },
  // proxy some particle attributes
  x:    function() { return this.get('particle').position.x; },
  y:    function() { return this.get('particle').position.y; },
  size: function() { return this.get('size');                },
  particle: function() { return this.get('particle'); },

  // Make a new node under this one
  createChild: function() {
    var mass = 0.4;
    // random x and y
    var x = this.x() + Math.random() * 50 - 25;
    var y = this.y() + Math.random() * 50 - 25;
    var z = 0;
  
    // make the physics particle
    var particle = Exobrain.makeParticle(mass, x, y, z);
    // make a model
    var node = new Exobrain.Node({particle: particle, size: 10});
    // add it to our child list
    this.children.add(node);

    // setup a spring between the new node and us
    var spring = 0.02;
    var damping = 0.10;
    var length = 120;
    Exobrain.makeSpring(this.particle(), node.particle(), spring, damping, length);

    // fire a child event for the node we created
    this.trigger('child', node);
    // when the node gets a child, make a link with this node
    node.on('child', this.link, this);
    // also, any child of our child is also our child, so all nodes link up the tree
    node.on('child', function(child) { this.trigger('child', child) }, this);

    return node;
  },
  // make a repulsive force with a node
  link: function(node, strength) {
    if (node === this) { return; }
    /* strength scales exponentially with distance, this keeps the system
     * from "folding up"
     */
    if (strength === undefined) {
      strength = -100.0;
    } else {
      strength = strength * 2.0;
    }
    var distanceMin = 5.0;
    Exobrain.makeAttraction(this.particle(), node.particle(), strength, distanceMin);
    this.children.each(function(child) { child.link(node, strength) }, this);
  }
});

/* Collection automatically links siblings */
Exobrain.NodeList = Backbone.Collection.extend({
  model: Node,
  initialize: function(models, options) {
    this.on('add', this.linkNodes, this);
  },
  linkNodes: function(node) {
    this.each(function(other) {
      other.link(node);
    }, this);
  }
})
</pre>

## Step 2. Raphael-based view
<pre class='prettyprint'>
Exobrain.NodeView = Backbone.View.extend({
  // make a child on click
  events: {
    'click': 'createChild'
  },
  initialize: function() {
    // draw a node, set "element" to the raphael node
    this.element = Exobrain.drawNode(
      this.model.x(), this.model.y(), this.model.size()
    );
    // set the dom element to the raphael element's dom node
    this.setElement(this.element.node);
    this.model.on('change', this.render, this);
  },
  // render will just move the node, not re-draw it
  render: function() {
    this.element.attr('cx', this.model.x());
    this.element.attr('cy', this.model.y());
  },
  // Create a new model and a view for it
  createChild: function() {
    new Exobrain.NodeView({model: this.model.createChild()})
  }
});

var Exobrain = {
  /* redacted */

  // draw a raphael node
  drawNode: function(x,y,size) {
    // make a circle on the Raphael "paper"
    var el = this.paper.circle(x,y,size);
    // fill it with red
    el.attr({fill: 'red'});
    return el;
  }

  /* redacted */
};
</pre>

## Notes

This is a great example of my style of Backbone programming. Make a namespace and put class definitions in it. Then only create instances within an onReady closure. No instances on the global namespaces!

The only exception was that I have a global physics engine set to the Exobrain object as well as a Raphael `paper` for drawing objects. I should probably make Exobrain a class and instantiate it with a div id, and have it allocate its own engine and paper.
