---
layout: post
title: Unsubscribe Links in Rails with ActiveSupport::MessageVerifier
date: 2013-01-08
---

If you're setting up an unsubscribe link for your emails in a Rails application, it's important to make it secure and seamless. We want to have it function properly if the user is not logged in without having them log in first. We also want to make sure it's not easy to forge. The url should be something like this:

http://example.com/unsubscribe/0938745209387452093478530938742509384752

So, we need some way to encode a user's information securely and create a url, then we also need to decode it. Enter <strong>ActiveSupport::MessageVerifier</strong>.

MessageVerifier is initialized with a secret, and can then encode and decode messages, like this:

<pre class='prettyprint'>
# make a verifier
verifier = ActiveSupport::MessageVerifier.new('secret')

# encode some data
token = verifier.generate('data')
# => "BAhJIglkYXRhBjoGRVQ=--7d0d0ec0f5572ac668afeabea7829064cc78223b"

# note: it's not encrypted!
Base64.decode64(token.split("--")[0])
# => "\x04\bI\"\tdata\x06:\x06ET"

# Get the data back out
verifier.verify(token)
# => "data"
</pre>

<strong>NOTE</strong>: the data is not encrypted, just verified with a digest using a secret. The original data is present in the token, so don't put anything secret in there.

Now, we can integrate this into our <code>User</code> model pretty easily. We'll make class methods for encoding and decoding, then an instance method to make it easier to use:

<pre class='prettyprint'>
class User < ActiveRecord::Base
  # Access token for a user
  def access_token
    User.create_access_token(self)
  end

  # Verifier based on our application secret
  def self.verifier
    ActiveSupport::MessageVerifier.new(MyRailsApp::Application.config.secret_token)
  end

  # Get a user from a token
  def self.read_access_token(signature)
    id = verifier.verify(signature)
    User.find_by_id id
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  # Class method for token generation
  def self.create_access_token(user)
    verifier.generate(user.id)
  end
end
</pre>

Now all we have to do is add a route:
<pre class='prettyprint'>
match '/users/unsubscribe/:signature' => 'users#unsubscribe', as: 'unsubscribe'
</pre>


Include the link in our email layout:
<pre class='prettyprint'>
&lt;%= link_to "Unsubscribe", unsubscribe_url(@user.access_token) %&gt;
</pre>

And setup a controller action:
<pre class='prettyprint'>
class UsersController < ApplicationController
  def unsubscribe
    if user = User.read_access_token(params[:signature])
      user.update_attribute :email_opt_in, false
      render text: "You have been unsubscribed"
    else
      render text: "Invalid Link"
    end
  end
end
</pre>

This can be expanded to be used in any scenario where you need an authentication token, for example all email links could contain a token in the param, which is removed in an application-wide <code>before_filter</code>. That way, a user never has to log in if they're coming from an email you sent them.

<strong>Warning</strong>: The data is encoded but since it is not (entirely) hashed it will grow in length. Be careful using variable-length or user-generated data, as you could go beyond the 2048 character limit of urls. Much like delayed jobs and cookies, it's a good idea to store only an identifier in the token, and then look up the associated data in your database. If you really need encryption, check out ActiveSupport::MessageEncryptor.
