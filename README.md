# Gmail Notifr #

A MacRuby Gmail Notifier for Mac OS X

# NOTE (2010/11/03) #
Gmail Notifr was implemented in RubyCocoa then rewritten in MacRuby.
The RubyCocoa implementation has been moved to the [rubycocoa](https://github.com/ashchan/gmail-notifr/tree/rubycocoa) branch. Master branch will focus on MacRuby.

![screenshot](http://ashchan.github.com/gmail-notifr/gmail-notifr-screen.png)

# Yet Another Gmail Notifier #

[Gmail Notifr](http://ashchan.com/projects/gmail-notifr) is written in MacRuby and has these features:

* Separate check and notification setting for each account.
* Support multiple accounts.
* Support Google hosted account.
* Check mail at a specified interval.
* Growl &amp; sound notifications.
* Small &amp; fast.
* Sparkle automatic updates.
* No background daemon processes installed as Google's official notifier.
* Open Source &amp; free!

# Requirements #

* Mac OS X 10.6 (Snow Leopard) or higher
* [MacRuby](http://macruby.com/) 0.9 (nightly build)
* [BridgeSupport](http://bridgesupport.macosforge.org/trac/wiki) Preview 3

# How to Build #

The Xcode project depends on [MacRuby Keychain Wrapper](https://github.com/ashchan/macruby-keychain-wrapper). It is added as a submodule. So don't forget to fetch it also:

    git clone git@github.com:ashchan/gmail-notifr.git
    git submodule init
    git submodule update

# Project Detail #

* View [project home page](http://ashchan.com/projects/gmail-notifr)

# Updates, Changelog & Feedback

* [Feedback](http://blog.ashchan.com/archive/2008/10/29/gmail-notifr-changelog/)

* [Changelog](http://assets.ashchan.com/gmailnotifr/release_notes.html)

# Binary Download

* [https://github.com/ashchan/gmail-notifr/downloads](https://github.com/ashchan/gmail-notifr/downloads)

# Source #

* [https://github.com/ashchan/gmail-notifr](https://github.com/ashchan/gmail-notifr)

# Copyright Info #

Copyright (c) 2008 - 2011 [James Chen](http://blog.ashchan.com) ([@ashchan](http://twitter.com/ashchan)), released under the MIT license
