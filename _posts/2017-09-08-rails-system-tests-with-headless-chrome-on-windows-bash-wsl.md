---
layout: post
title: Rails Systems Tests with Headless Chrome on Windows Bash (WSL)
date: 2017-09-08
---

I've been using the Windows Subsystem for Linux for a few months now, but one thing I hadn't figured out was how to run selenium tests from it. WSL doesn't support GUI applications, and Chrome is especially difficult to get working. So even thought I want to use `chromedriver` with the new `headless` option, Chrome still doesn't work properly in WSL out of the box.

Thanks to [a tweet from Jessie Frazelle](https://twitter.com/jessfraz/status/905936903358345216) in which she mentioned that you can run Windows binaries from WSL, I had the idea to give this another shot: have my Rails tests in WSL call out to *Windows chromedriver.exe* to drive a headless browser using Windows Chrome. Turns out it works! Here's how to do it.

## Start with a blog of course

So we need some kind of Rails app. I'm going to show you how to set it up so that if you just want to tinker you can try it out quickly.

<pre class='prettyprint'>
$ rails new blog
$ cd blog
$ rails generate system_test hello
$ rails db:migrate
$ rails test:system
</pre>

It should show no tests to run. Let's write one to try it out. Edit **test/system/hellos_test.rb**:

<pre class='prettyprint'>
require "application_system_test_case"

class HellosTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit '/'
    assert page.has_content?('oh hai')
  end
end
</pre>

If you run this, it won't work, because Selenium can't find the chromedriver:

<pre>
$ rails test:system
Run options: --seed 9949

# Running:

E

Error:
HellosTest#test_visiting_the_index:
Selenium::WebDriver::Error::WebDriverError:  Unable to find chromedriver. Please download the server from http://chromedriver.storage.googleapis.com/index.html and place it somewhere on your PATH. More info at https://github.com/SeleniumHQ/selenium/wiki/Chr
omeDriver.

    test/system/hellos_test.rb:5:in `block in &lt;class:HellosTest&gt;'

Error:
HellosTest#test_visiting_the_index:
Selenium::WebDriver::Error::WebDriverError:  Unable to find chromedriver. Please download the server from http://chromedriver.storage.googleapis.com/index.html and place it somewhere on your PATH. More info at https://github.com/SeleniumHQ/selenium/wiki/Chr
omeDriver.




bin/rails test test/system/hellos_test.rb:4



Finished in 0.749730s, 1.3338 runs/s, 0.0000 assertions/s.
1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
</pre>

## Install chromedriver

[Go download chromedriver from Google](https://sites.google.com/a/chromium.org/chromedriver/). Put it somewhere you plan on adding to your path. Like `Documents\bin`.

Now, add that directory to your path:

1. Hit the Windows key and type `environment`
2. Open the "Edit the system environment variables" app
3. Click "Environment Variables".
4. Click "Path"
5. Click "Edit"
6. Click "New"
7. Click "Browse"
8. Browse to your directory you're going to use (I used `Documents\bin`)
9. Click OK, OK, OK

Now **relaunch your terminal** to pick up the new environment variables. You can `echo $PATH` to ensure it's on there. You should be able to run:

<pre>
$ chromedriver.exe -v
ChromeDriver 2.32.498550 (9dec58e66c31bcc53a9ce3c7226f0c1c5810906a)
</pre>

Finally, we need to do one of two things:

1. Rename `chromedriver.exe` to `chromedriver`
2. Make a `chromedriver` bash wrapper inside WSL

This is because Selenium looks for a `chromedriver` binary, not `chromedriver.exe`. Renaming is the easiest, that's what I did.

## Run it and go headless

If you run your tests now, it should pop open a Windows Chrome window and fail the test (because we didn't actually write code to pass it).

<pre>
$ rails test:system
/home/nick/.gems/gems/railties-5.1.3/lib/rails/app_loader.rb:40: warning: Insecure world writable dir /mnt/c/Users/Nick/Documents/GitHub/blog in PATH, mode 040777
Run options: --seed 5589

# Running:

Puma starting in single mode...
* Version 3.10.0 (ruby 2.4.1-p111), codename: Russell's Teapot
* Min threads: 0, max threads: 1
* Environment: test
* Listening on tcp://0.0.0.0:50511
Use Ctrl-C to stop
2017-09-08 09:44:45 -0400: Rack app error handling request { GET / }
#&lt;ActionController::RoutingError: No route matches [GET] "/"&gt;
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/debug_exceptions.rb:63:in `call'
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/show_exceptions.rb:31:in `call'
/home/nick/.gems/gems/railties-5.1.3/lib/rails/rack/logger.rb:36:in `call_app'
/home/nick/.gems/gems/railties-5.1.3/lib/rails/rack/logger.rb:24:in `block in call'
/home/nick/.gems/gems/activesupport-5.1.3/lib/active_support/tagged_logging.rb:69:in `block in tagged'
/home/nick/.gems/gems/activesupport-5.1.3/lib/active_support/tagged_logging.rb:26:in `tagged'
/home/nick/.gems/gems/activesupport-5.1.3/lib/active_support/tagged_logging.rb:69:in `tagged'
/home/nick/.gems/gems/railties-5.1.3/lib/rails/rack/logger.rb:24:in `call'
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/remote_ip.rb:79:in `call'
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/request_id.rb:25:in `call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/method_override.rb:22:in `call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/runtime.rb:22:in `call'
/home/nick/.gems/gems/activesupport-5.1.3/lib/active_support/cache/strategy/local_cache_middleware.rb:27:in `call'
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/executor.rb:12:in `call'
/home/nick/.gems/gems/actionpack-5.1.3/lib/action_dispatch/middleware/static.rb:125:in `call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/sendfile.rb:111:in `call'
/home/nick/.gems/gems/railties-5.1.3/lib/rails/engine.rb:522:in `call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/urlmap.rb:68:in `block in call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/urlmap.rb:53:in `each'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/urlmap.rb:53:in `call'
/home/nick/.gems/gems/rack-2.0.3/lib/rack/builder.rb:153:in `call'
/home/nick/.gems/gems/capybara-2.15.1/lib/capybara/server.rb:44:in `call'
/home/nick/.gems/gems/puma-3.10.0/lib/puma/configuration.rb:225:in `call'
/home/nick/.gems/gems/puma-3.10.0/lib/puma/server.rb:605:in `handle_request'
/home/nick/.gems/gems/puma-3.10.0/lib/puma/server.rb:437:in `process_client'
/home/nick/.gems/gems/puma-3.10.0/lib/puma/server.rb:301:in `block in run'
/home/nick/.gems/gems/puma-3.10.0/lib/puma/thread_pool.rb:120:in `block in spawn_thread'
[Screenshot]: tmp/screenshots/failures_test_visiting_the_index.png

E

Error:
HellosTest#test_visiting_the_index:
ActionController::RoutingError: No route matches [GET] "/"



bin/rails test test/system/hellos_test.rb:4



Finished in 6.261807s, 0.1597 runs/s, 0.0000 assertions/s.
1 runs, 0 assertions, 0 failures, 1 errors, 0 skips
/home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `waitpid2': Invalid argument (Errno::EINVAL)
        from /home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:138:in `process_exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:123:in `stop_process'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `ensure in stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/chrome/driver.rb:69:in `quit'
        from /home/nick/.gems/gems/capybara-2.15.1/lib/capybara/selenium/driver.rb:276:in `quit'
        from /home/nick/.gems/gems/capybara-2.15.1/lib/capybara/selenium/driver.rb:32:in `block in browser'
/home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `waitpid2': Invalid argument (Errno::EINVAL)
        from /home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:138:in `process_exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:123:in `stop_process'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `ensure in stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:69:in `block in start'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/platform.rb:138:in `block in exit_hook'
</pre>

Also you'll notice there's an error at the end with `waitpid2`. I don't know how to fix that. But it does run our test so I'm happy enough for now.

Let's pass the test. Edit `config/routes.rb`:

<pre class='prettyprint'>
Rails.application.routes.draw do
  root to: 'application#index'
end
</pre>

Edit `app/views/application/index.html.erb`:

<pre class='prettyprint'>
oh hai
</pre>

And run. It should pass now.

[Following this post from thoughtbot](https://robots.thoughtbot.com/headless-feature-specs-with-chrome) edit `test/application_system_test_case.rb`:

<pre class='prettyprint'>
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome, screen_size: [1400, 1400]
end


Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w(headless disable-gpu) }
  )

  Capybara::Selenium::Driver.new app,
    browser: :chrome,
    desired_capabilities: capabilities
end
</pre>

And run it, and it's headless! Super cool.

<pre>
$ rails test:system
/home/nick/.gems/gems/railties-5.1.3/lib/rails/app_loader.rb:40: warning: Insecure world writable dir /mnt/c/Users/Nick/Documents/GitHub/blog in PATH, mode 040777
Run options: --seed 28393

# Running:

Puma starting in single mode...
* Version 3.10.0 (ruby 2.4.1-p111), codename: Russell's Teapot
* Min threads: 0, max threads: 1
* Environment: test
* Listening on tcp://0.0.0.0:50621
Use Ctrl-C to stop
.

Finished in 4.973954s, 0.2010 runs/s, 0.2010 assertions/s.
1 runs, 1 assertions, 0 failures, 0 errors, 0 skips
/home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `waitpid2': Invalid argument (Errno::EINVAL)
        from /home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:138:in `process_exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:123:in `stop_process'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `ensure in stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/chrome/driver.rb:69:in `quit'
        from /home/nick/.gems/gems/capybara-2.15.1/lib/capybara/selenium/driver.rb:276:in `quit'
        from /home/nick/.gems/gems/capybara-2.15.1/lib/capybara/selenium/driver.rb:32:in `block in browser'
/home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `waitpid2': Invalid argument (Errno::EINVAL)
        from /home/nick/.gems/gems/childprocess-0.7.1/lib/childprocess/unix/process.rb:32:in `exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:138:in `process_exited?'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:123:in `stop_process'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `ensure in stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:83:in `stop'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/service.rb:69:in `block in start'
        from /home/nick/.gems/gems/selenium-webdriver-3.5.2/lib/selenium/webdriver/common/platform.rb:138:in `block in exit_hook'
</pre>