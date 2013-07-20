---
layout: post
title: WebSockets in Rails 4
date: 2013-03-12
---

I've been using Rails 4 (beta) a lot recently. In a previous post we looked at how ActionController::Live can be used with Server-Sent Events, but the problem with that is that there's no way for the client to communicate back to the web server. Enter: WebSockets.

The main issue with implementing WebSockets is that they have to keep their connections open for a long period of time, and when you're only running a small cluster of Rails servers, it eats up potential connections fast. That's why I was excited to hear about two important developments: concurrency in Rails 4 and Rack Hijack.

## Concurrency in Rails 4

Rails 4 is now full concurrent, which means that there is no full-stack lock on a request. That means that if you use a concurrent server like Puma you can handle many requests at a time with a single process.

Even better, you can use ruby Threads inside your Rails app. That's how ActionController::Live works (for streaming).

What this means for us is that we can use Threads to hold websocket connections open without bogging down our server.

Also, this means that our solution does not use Eventmachine, nor does it implement a reactor in any way. It's concurrent.

## Rack Hijack

Rack Hijack came with Rack 1.5.0 which was released this past January. Rack hijack allows you to access the underlying socket of a Rack connection in order to bidirectionally communicate with the client. Since Rails is built on Rack we can grab a handle to the client socket *right from a Rails controller*.


## Tubesock

Tubesock is the gem that I made to encapsulate this functionality. It's very small and new and untested so caveat emptor and all that. At its core it provides a module for Rails controllers and a wrapper method to hijack the rack connection. Then it wraps the ruby gem `websocket` to handle WebSocket handshakes and frames. Here's an example of using it in a controller:

<pre class="prettyprint">
class ChatController < ApplicationController
  include Tubesock::Hijack

  def chat
    hijack do |tubesock|
      tubesock.onopen do
        tubesock.send_data "Hello, friend"
      end

      tubesock.onmessage do |data|
        tubesock.send_data message: "You said: #{data}"
      end
    end
  end
end
</pre>

Right inside the controller action we can hijack the connection and then use some blocks to send information.

You can check out [the Tubesock gem on Github](http://github.com/ngauthier/tubesock) for more information.

Also, there is an [example chat application](http://github.com/ngauthier/sock-chat) you can run and play with.

Happy hacking!
