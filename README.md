# Gmail Notifr #

A MacRuby Gmail Notifier for Mac OS X

_Note: The RubyCocoa implementation has been moved to the [rubycocoa](https://github.com/ashchan/gmail-notifr/tree/rubycocoa) branch._

![screenshot](http://ashchan.github.com/gmail-notifr/gmail-notifr-screen.png)

## Yet Another Gmail Notifier ##

[Gmail Notifr](http://ashchan.com/projects/gmail-notifr) is written in MacRuby with these features:

* Support multiple accounts.
* Separate check and notification setting for each account.
* Preferred browser setting for each account.
* Support Google hosted account.
* Check mail at a specified interval.
* Growl &amp; sound notifications.
* Small &amp; fast. *
* Sparkle automatic updates.
* No background daemon processes installed as Google's official notifier.
* Open Source &amp; free!

_* MacRuby is private framework on Lion, Gmail Notifr needs to embed the framework so the final size is kind of 'big' comparing to RubyCocoa version. Memory usage is bigger (30MB+) due to the same reason._

## Requirements ##

* Mac OS X 10.6 (Snow Leopard) or higher
* An Intel 64-bit machine
* [MacRuby](http://macruby.com/) 1.0 (nightly build, 2011-07-22 or newer)
* [BridgeSupport](http://bridgesupport.macosforge.org/trac/wiki) Preview 3

## How to Build ##

The Xcode project depends on [MacRuby Keychain Wrapper](https://github.com/ashchan/macruby-keychain-wrapper). It is added as a submodule. So don't forget to fetch it:

    git clone https://github.com/ashchan/gmail-notifr.git
    git submodule init
    git submodule update

or use --recursive option:

    git clone --recursive git@github.com:ashchan/gmail-notifr.git

## Updates, Changelog & Feedback ##

Feedback is welcome! Leave a message on the [feedback](http://blog.ashchan.com/archive/2008/10/29/gmail-notifr-changelog/) page, or create a github [issue](https://github.com/ashchan/gmail-notifr/issues), or tweet the author [@ashchan](http://twitter.com/#!/ashchan).

View the full [changelog](http://assets.ashchan.com/gmailnotifr/release_notes.html).

Visit [project home page](http://ashchan.com/projects/gmail-notifr) for more information.

## Binary Download ##

* [https://github.com/ashchan/gmail-notifr/downloads](https://github.com/ashchan/gmail-notifr/downloads)

_Note: versions <= 0.5.2 do NOT run on OS X Lion._

## License ##

(The MIT License)

Copyright (c) 2008 - 2012 [James Chen](http://ashchan.com/) ([@ashchan](http://twitter.com/#!/ashchan))

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
