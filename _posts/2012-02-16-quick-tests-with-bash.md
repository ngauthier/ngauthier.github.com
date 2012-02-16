---
layout: post
title: Quick Ruby Tests with Bash
date: 2012-02-16
---

In Ruby on Rails development, we have great gems like [Guard](https://github.com/guard/guard) that will re-run tests or other tasks based on changing files. I was interested in finding something more lightweight but less configurable and flexible that I could use on smaller projects.

I ended up writing this quick bash script that I put on my path called `live`:

<pre class='prettyprint'>
#/usr/bin/env sh
# Usage "live command"
clear
$*
while inotifywait -qr -e close_write *; do clear; $*; done
</pre>

This script takes a command as an argument and re-runs the command whenever any file in the current directory changes. So, you can simply re-run the tests of a project by running `live rake`. Or, you could re-output a project directory with `live tree`. It's like `watch` except evented on write changes.

The next thing I noticed while using this on larger (rails) projects is that project boot is slow and the tests run in different groups that each boot the environment.

Note the raw time it takes to run the project's tests:
<pre class='prettyprint'>
$ time rake
Loaded suite /home/nick/workspace/giftsmart/.bundle/gems/ruby/1.9.1/gems/rake-0.9.2.2/lib/rake/rake_test_loader
Started
....
Finished in 0.588015 seconds.

4 tests, 30 assertions, 0 failures, 0 errors, 0 skips

Test run options: --seed 54473
Loaded suite /home/nick/workspace/giftsmart/.bundle/gems/ruby/1.9.1/gems/rake-0.9.2.2/lib/rake/rake_test_loader
Started
...............
Finished in 3.679384 seconds.

15 tests, 77 assertions, 0 failures, 0 errors, 0 skips

Test run options: --seed 45532

real  0m41.495s
user  0m38.502s
sys   0m1.928s
</pre>

Seriously?! 41.5 seconds to run just over 4 seconds worth of tests? [WAT?](https://www.destroyallsoftware.com/talks/wat) And this is using ruby-1.9.3-falcon!

So, my first step was to merge the environments and optionally skip `db:reset`:

<pre class='prettyprint'>
# lib/tasks/testing.rake
namespace :test do
  desc 'Run tests quickly by merging all types and not resetting db'
  Rake::TestTask.new('fast') do |t|
    t.libs << 'test'
    t.pattern = "test/**/*_test.rb"
  end

  namespace :fast do
    desc 'Run tests quickly, but also reset db'
    task :db => ['db:test:prepare', 'test:fast']
  end
end
</pre>

This provides `rake test:fast:db` which reset the db and runs the tasks merged as one, and `rake test:fast` which merges the tasks and doesn't reset the db. Here's the result:

<pre class='prettyprint'>
$ time rake test:fast:db
Loaded suite /home/nick/workspace/giftsmart/.bundle/gems/ruby/1.9.1/gems/rake-0.9.2.2/lib/rake/rake_test_loader
Started
...................
Finished in 3.752755 seconds.

19 tests, 107 assertions, 0 failures, 0 errors, 0 skips

Test run options: --seed 57655

real  0m28.430s
user  0m26.138s
sys   0m1.216s
</pre>

OK, that's a 46% improvement. Now, without the db:

<pre class='prettyprint'>
$ time rake test:fast
Loaded suite /home/nick/workspace/giftsmart/.bundle/gems/ruby/1.9.1/gems/rake-0.9.2.2/lib/rake/rake_test_loader
Started
...................
Finished in 3.790390 seconds.

19 tests, 107 assertions, 0 failures, 0 errors, 0 skips

Test run options: --seed 53405

real  0m21.623s
user  0m20.525s
sys   0m1.020s
</pre>

Better, a 92% improvement! But it's still 3.8 seconds worth of test at 21.6 seconds. Lame.

Now it's time for drastic measures. When I'm running tests, I see this process:

<pre class='prettyprint'>
/usr/bin/ruby1.9.1 -Ilib:test /path/to/my/project/.bundle/gems/ruby/1.9.1/gems/rake-0.9.2.2/lib/rake/rake_test_loader.rb test/unit/**/*_test.rb
</pre>

This is because Rake::TestTask shells out to ruby to keep the environment clean. This works great for projects with minimal boot times. But in my case, I have a much larger Rails boot I have to worry about. This means I'm still booting Rails twice!

So, I made a short ruby script that gives me direct access to the rake test loader for the current project:

<pre class='prettyprint'>
#!/usr/bin/env sh
ruby -Ilib:test `bundle list rake`/lib/rake/rake_test_loader.rb $*
</pre>

Now, here are my results:
<pre class='prettyprint'>
$ time rtest test/**/*_test.rb
Run options:

# Running tests:

...................

Finished tests in 3.070074s, 6.1888 tests/s, 34.8526 assertions/s.

19 tests, 107 assertions, 0 failures, 0 errors, 0 skips

real  0m9.579s
user  0m9.089s
sys   0m0.324s
</pre>

There we go! That's 333% faster! Now the total time to run my tests is 1xRails and 1xTest. This is probably the minimal boot time I could get without keeping the environment hot loaded. The best part is, I can combine my two scripts:

<pre class='prettyprint'>
$ live time rtest test/**/*_test.rb
</pre>

Now I have a very fast and minimal live-updating setup written in 4 lines of bash that is portable across projects.
