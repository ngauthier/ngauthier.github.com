---
layout: post
title: Using Docker to Parallelize Rails Tests
date: 2013-10-13
---

Docker is a new way to containerize services. The primary use so far has been for deploying services in a very thin container. I experimented with using it for Rails Continuous Integration so that I could run tests within a consistent environment, and then I realized that the containers provide excellent encapsulation to allow for parallelization of test suites.

There are three things we'll have to do to run a Rails test suite in parallel in docker:

1. Create a Dockerfile for a system that can run our tests, and build the container
2. Create a script that breaks our tests across multiple containers
3. Create a script to run the tests within an individual container

## Dockerfile and Container

Dockerfiles are quite simple. The majority of the commands are usually RUN commands that run instructions on the container. Let's take a look:

<pre class='prettyprint'>
from tianon/debian:sid
maintainer Nick Gauthier ngauthier@gmail.com

run apt-get update
run apt-get -qy dist-upgrade

run apt-get install -yq postgresql-9.3 libpq-dev nodejs ruby2.0 ruby2.0-dev build-essential
run gem install bundler --no-ri --no-rdoc --pre
</pre>

The FROM line bases our container off of debian unstable. I'm using this source because it has ruby 2.0 and postgresql 9.3 right in apt, so the installation is minimal and fast.

Then, we update the system, install postgresql, node (for assets), ruby, and building libraries for gem extenions.

Finally, we install bundler.

Now, we can build our container via:

<pre>
docker build -t username/appname .
</pre>

That will build the current directory's container and tag it with `username/appname` (so you should replace that with your name and your app's name). I am not sure yet how to do this in a more portable and anonymous fashion.

## Parallelization Script

Next, we're going to write `bin/docker-ci`. The goal of this script is to split our tests across multiple containers, and ultimately call `bin/ci` *within* the containers.

`bin/docker-ci`

<pre class='prettyprint'>
#!/usr/bin/env bash
set -e

# Make our tmp directory for gems
mkdir -p /tmp/docker

# Docker options:
# Mount the current directory to /data/code
# Mount the temp directory to /data/gems
# Set GEM_HOME to the data directory
# Set the working directory to the code directory
# Use our built container
opts="-v `readlink -f .`:/data/code
      -v /tmp/docker:/data/gems
      -e GEM_HOME=/data/gems
      -w /data/code
      username/appname"

# Bundle the gems (once, serially)
docker run $opts bundle --quiet

# Spread test files in large groups, and pass them into the
# container's bin/ci method
ls test/**/*_test.rb | parallel -X docker run $opts /data/code/bin/ci
</pre>

The `-v` options allow us to share the current machine's code directory with the container. One issue here is that any file system operations within the code folder could conflict across containers.

We're using GNU parallel with the -X flag, which will spread the test files into larger chunks, as oposed to one job per test file. I don't think this perfectly utilizes all the cores on my machine, so some more tweaking could be done here.

At this point, `bin/ci` is run with one or more test files as parameters.

## Test running script

The `bin/ci` script needs to run a set of test files, and it will also need to initialize the container so that the suite can run.

<pre class='prettyprint'>
#!/usr/bin/env bash
set -e
# Start postgresql
service postgresql start
# Create the db
su -c "createuser root -s" postgres
# prep the db
bundle exec rake db:test:prepare
# require test files from the arguments given to this script
ruby -I.:test -e "ARGV.each{|f| require f}" $*
</pre>

We have to boot up and initialize postgresql because containers don't preserve running services, they are simply file systems that can be booted up. We also want to do this each time because we'd rather load the db than build it into the container and have to rebuild the container when our schema changes.

I'm using ruby with require, but here you could substitute any way that says "run the following test files". `rspec`'s binary would work well, and also the `m` binary. I just stuck a simple ruby script here that should be suite-agnostic.

## Summary

And that's it! It's actually fairly simple, but it took me a while to stick everything together. I think there are certainly some refinements to be made to generalize it a bit better. For example, you could use any container from the docker index that provides a good rails base for your app. That way you wouldn't have to maintain a Dockerfile in the project.

Also, I'm not currently seeing any performance improvements due to the parallelization, but that's because it's a very short suite, so the overhead of doing a bundle check and db initialization outweighs the savings of parallelism.

Try it on your app, I'd love to hear the results.
