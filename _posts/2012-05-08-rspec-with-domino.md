---
layout: post
title: RSpec with Domino
date: 2012-05-08
---

Using [Domino](http://rubydoc.info/gems/domino/frames) with [RSpec](http://rubydoc.info/gems/rspec/frames) is awesome. I'll let the code speak for itself.

We have an html page:

<pre class='prettyprint'>
&lt;!doctype html&gt;
&lt;html&gt;
  &lt;head&gt;
    &lt;title&gt;Domino Rspec&lt;/title&gt;
  &lt;/head&gt;
  &lt;body&gt;
    &lt;h1&gt;Domino Rspec&lt;/h1&gt;
    &lt;ul&gt;
      &lt;li&gt;&lt;span class='name'&gt;John Doe&lt;/span&gt; Age &lt;span class='age'&gt;47&lt;/span&gt;&lt;/li&gt;
      &lt;li&gt;&lt;span class='name'&gt;Jane Doe&lt;/span&gt; Age &lt;span class='age'&gt;37&lt;/span&gt;&lt;/li&gt;
      &lt;li&gt;&lt;span class='name'&gt;Jim Doe&lt;/span&gt; Age &lt;span class='age'&gt;27&lt;/span&gt;&lt;/li&gt;
    &lt;/ul&gt;
  &lt;/body&gt;
&lt;/html&gt;
</pre>

And here is an rspec request spec to test the data:

<pre class='prettyprint'>
describe :index_without_domino, :type => :request do
  before do
    visit '/'
  end

  it 'should have three people' do
    page.all('ul li').count.should == 3
  end

  context 'John Doe' do
    subject do
      page.all('ul li').find do |node|
        node.find('.name').text == 'John Doe'
      end
    end

    it 'should have an age of 47' do
      subject.find('.age').text.should == '47'
    end
  end
end
</pre>

CSS selectors are brittle here, and it's not very rubyish. It's full of html! First, we'll make a domino:

<pre class='prettyprint'>
module Dom
  class Person < Domino
    selector 'ul li'
    attribute :name
    attribute :age
  end
end
</pre>

And then update our test:

<pre class='prettyprint'>
describe :index, :type => :request do
  before do
    visit '/'
  end

  it 'should have three people' do
    Dom::Person.count.should == 3
  end

  context 'John Doe' do
    subject { Dom::Person.find_by_name 'John Doe' }
    its(:age) { should == '47' }
  end
end
</pre>

Because dominos are enumerable ruby objects, we can count them easily. There's also handy attribute finders and accessors. So, a domino can be an rspec subject. Much better!

[Full project source code](http://github.com/ngauthier/domino_rspec)
