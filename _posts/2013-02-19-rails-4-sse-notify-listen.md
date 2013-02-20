---
layout: post
title: Rails 4 Server Sent Events with ActionController::Live and PostgreSQL NOTIFY/LISTEN
date: 2013-02-19
---

I had a simple problem: one user takes an action, and I want it to be reflected immediately on another user's screen.

There are lots of potential ways to solve this: polling, long polling, websockets, etc. However I had a specific goal in mind: **use the stack I already had** and keep complexity to a minimum. I didn't want to use websockets because of the extra setup on the server. Nginx just got a websockets proxy patch, but I don't feel like compiling nginx from source on my deployment machines. I wanted something evented, but I didn't want to add another back-end service like Redis.

I decided to use Rails 4's ActionController::Live, HTML5 Server Sent Events, and PostgreSQL's NOTIFY/LISTEN system. The best part is that all I had to do to my stack was swap thin for puma.

Huge thanks to Aaron Patterson for his post [Is it Live?](http://tenderlovemaking.com/2012/07/30/is-it-live.html). Go read that now, because that's how I implemented ActionController::Live, SSEs, and the Javascript.


One thing I did do, though, was refactor (or unprefactor) his SSE implementation. Instead of a model I just added a controller method, so my controller action looks like:

<pre class='prettyprint'>
def index
  response.headers['Content-Type'] = 'text/event-stream'
  deck.on_slide_change do |slide|
    response.stream.write(sse({slide: slide}, {event: 'slide'}))
  end
rescue IOError
  # Client Disconnected
ensure
  response.stream.close
end

private
def sse(object, options = {})
  (options.map{|k,v| "#{k}: #{v}" } << "data: #{JSON.dump object}").join("\n") + "\n\n"
end
</pre>

This application is broadcasting a slide change on a deck, and every time a change occurs, it will write an SSE. My client consumes the feed just like Aaron's, and then I also have a "broadcaster" that sends plain old ajax PUT requests to update the deck slide.

Aaron used rb-fsevent which is an evented file system watching gem for OS X. In my case, I wanted my events to come from the database, so I used PostgreSQL's NOTIFY/LISTEN. It's really simple pub/sub that just takes a channel and a payload, and it all operates in shared memory. So it wouldn't be great for a resilient queue, but it's great for messaging.

Here's how I added that in my ActiveRecord model:

<pre class='prettyprint'>
after_save :notify_slide_change
def notify_slide_change
  if current_slide_changed?
    connection.execute "NOTIFY #{channel}, #{connection.quote current_slide.to_s}"
  end
end

def on_slide_change
  connection.execute "LISTEN #{channel}"
  loop do
    connection.raw_connection.wait_for_notify do |event, pid, slide|
      yield slide
    end
  end
ensure
  connection.execute "UNLISTEN #{channel}"
end

private
def channel
  "decks_#{id}"
end
</pre>

Whenever it's saved and the slide has changed, I send a notify on the channel with the current slide as a string payload. The channel is simply the table name and id stuck together.

<code>on_slide_change</code> is where it starts to get interesting. I listen on the channel (with an <code>ensure</code> to stop listening). Then I have to get the <code>pg</code> gem's raw connection so I can call <code>wait_for_notify</code>, which is a blocking LISTEN. It will give me an event, a pid, and my payload, which in my case is the slide. In true Ruby style, I yield the slide.

All in all, it was pretty simple, but also pretty difficult to setup. One thing that is particularly tricky is that you have to cache classes in development mode in order to multithread Rails on Puma, which means you have to reboot your server on code changes. Also, I had to make sure my DB connection pool in <code>database.yml</code> was as high as my Puma thread pool so everyone could have a DB connection.
