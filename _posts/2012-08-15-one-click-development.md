---
layout: post
title: One Click Development
date: 2012-08-15
---

## The Problem

Non-technical teammates can't run the app. You've got designers, project managers, qa, and more. Whenever developers add a dependency to the project, a lot of hand-holding needs to occur to get everyone setup.

Not everyone is comfortable on the terminal, nor should they be.

## go.sh

My first solution to this problem was to place `go.sh` in the root of the project. This command installed bundler, bundled the project, and ran the server. This worked fine, until the first dependency shift: switching from sinatra to rails with postgresql.

I've been doing rails for about five years now, and I got a mac a few months ago. I'm embarassed and frustrated at how long it took me to figure out xcode's command line tools, homebrew, rbenv on OS X, starting and stopping processes, database permissions, etc. How can I ask that of someone who does not have a terminal on their dock?

Many great minds are working on making Rails setup on OS X better, and that's great. But it's not enough. Developers will always be one step ahead, using the latest and greatest tools, and we don't want to wait for others to setup one-click installs for the stack we want.


## Vagrant

So now, I turn to [Vagrant](http://vagrantup.com). I've wanted to try it out, but I've had no real excuse, until now. So here's my goal:

**go.sh should download, boot, provision, and run the rails app with minimal requirements**

## Pre-requisites

Thanks to those working on making OS X setup easier, the OS X specific pre-requisites are:

1. Download and install [RailsInstaller](http://railsinstaller.org/)
1. Download and install [VirtualBox](https://www.virtualbox.org/)

On linux, it's:

1. `apt-get install ruby virtualbox`


We need VirtualBox for vagrant, and we need railsinstaller to get ruby 1.9 for vagrant.

## Running the project

Create a symlink to `go.sh` called `go.command` for mac, so those users can simply double click.

**Double click go** is now the way to run the system. Then the user browses to localhost:5000


## OK, so, HOW???

### go.sh

<pre class='prettyprint'>
#!/bin/sh

# Ensure we're in the project directory
cd `dirname $0`

# Setup gems to install to userspace
export GEM_HOME=$HOME/.gems
export PATH=$GEM_HOME/bin:$PATH

# Output debug info in case a developer needs to lend a hand
echo "Working in `pwd`"
echo "Ruby `ruby -v`"
echo "Rubygems `gem -v`"

# Install vagrant if it's not installed
vagrant -v 2>/dev/null || gem install vagrant --no-ri --no-rdoc

# Create, boot, provision vm (more later)
vagrant up

# On the vagrant box, run our custom server script
vagrant ssh -c "cd /vagrant && ./script/server"
</pre>

### script/server

Hey, remember this from rails 2? I wrote a custom script/server that does all the things that *really* need to be done to run a rails server:

<pre class='prettyprint'>
#!/bin/sh

# Setup local paths
export GEM_HOME=$HOME/.gems
export PATH=$GEM_HOME/bin:$PATH

# Install bundler if not available
bundle -v 2>/dev/null || gem install bundler --no-rdoc --no-ri

# Install all gems (or update, after pulling new code)
bundle install

# Create db if it doesn't exist, migrate if we need to
bundle exec rake db:create db:migrate

# Start services
bundle exec foreman start
</pre>

Also, savvy devs would be expected to provision their own system, then run script/server locally (not in a vm) for extra performance. Or, for better consistency, they could run vagrant too.

### stop.sh

Lastly, there is a `stop.sh`. You can ctrl+c and/or close the terminal created by `go.sh` but that won't halt the vm.

<pre class='prettyprint'>
#!/bin/sh
cd `dirname $0`
export GEM_HOME=$HOME/.gems
export PATH=$GEM_HOME/bin:$PATH

vagrant halt
</pre>

## Provisioning

Now the only remaining question is how to setup vagrant for a nice rails environment. Here is my `Vagrantfile`:

<pre class='prettyprint'>
Vagrant::Config.run do |config|
  # Use ubuntu 12.04 32 bit
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  # Forward port 5000 to localhost:5000
  config.vm.forward_port 5000, 5000

  # Use chef-solo to provision
  config.vm.provision :chef_solo do |chef|
    # Use our custom recipe
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "my_application"
  end
end
</pre>

Vagrant and Chef are entirely new to me (as of yesterday), so this is the area **I'm not sure on**. I used [librarian](https://github.com/applicationsonline/librarian) initially, but found that I needed more control over the recipes and box setup, and that I could use a much simpler recipe and only target ubuntu. [Bryan Liles](http://smartic.us/) pointed me at chef's [packages](http://wiki.opscode.com/display/chef/Resources#Resources-Package) and [scripts](http://wiki.opscode.com/display/chef/Resources#Resources-Script), and so I wrote my own simple cookbook called `my_application` (I actually named it the same as the Rails app).

Now, vagrant just grabs an ubuntu 12.04 base image, forwards port 5000, and runs my cookbook. The cookbook only needed two files, `cookbooks/my_application/metadata.rb` which was just my name and info, and then `cookbooks/my_application/default.rb`:

<pre class='prettyprint'>
# Update repository and install any upgrades
execute "update apt" do
  command "apt-get update && apt-get upgrade -y"
end

# Install ruby and postgresql and dependencies for gems and rails
package 'libxslt1-dev'
package 'libxml2-dev'
package 'build-essential'
package 'g++'
package 'ruby1.9.1-dev'
package 'postgresql'
package 'libpq-dev'
package 'git'
package 'nodejs'

# Create a directory for us to put some lock files in so scripts run once
execute "application directory" do
  command "mkdir /var/my_application"
  creates "/var/my_application"
end

# Setup vagrant as a psql user
execute "vagrant psql role" do
  command %{sudo -u postgres createuser -s vagrant         && \
            sudo -u postgres createdb   -O vagrant vagrant && \
            touch /var/my_application/psql-vagrant.done}
  creates        "/var/my_application/psql-vagrant.done"
end
</pre>

I'm used to a pretty minimal ubuntu setup like this. Much faster and easier than using rvm or rbenv. System ruby is 1.9.3p194 on ubuntu 12.04, which is rvm's default ruby 1.9 as well. And you don't have to compile it!

## Team workflow

So now, non-technical team members have a running app on their system. Developers can add dependencies to the cookbook, and when a non-technical team member syncs their code (with Github's apps, right?) they can just click `go` and vagrant will update the box based on the new provisions, and the server script will update the system's gems and database. Sweet!
