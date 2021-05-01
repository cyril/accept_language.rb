# Accept Language

A tiny library for parsing the `Accept-Language` header from browsers (as defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4)).

## Status

[![Gem Version](https://badge.fury.io/rb/accept_language.svg)](https://badge.fury.io/rb/accept_language)
[![Build Status](https://travis-ci.org/cyril/accept_language.rb.svg?branch=master)](https://travis-ci.org/cyril/accept_language.rb)
[![Inline Docs](https://inch-ci.org/github/cyril/accept_language.rb.svg)](https://inch-ci.org/github/cyril/accept_language.rb)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "accept_language"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install accept_language

## Usage

It's intended to be used in a Web server that supports some level of internationalization (i18n), but can be used anytime an `Accept-Language` header string is available.

Examples:

```ruby
AcceptLanguage.parse("da, en-gb;q=0.8, en;q=0.7")                     # => {:da=>1.0, :"en-gb"=>0.8, :en=>0.7}
AcceptLanguage.parse("fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5")  # => {:"fr-ch"=>1.0, :fr=>0.9, :en=>0.8, :de=>0.7, :*=>0.5}
```

In order to help facilitate better i18n, a method is provided to return the intersection of the languages the user prefers and the languages your application supports.

Examples:

```ruby
AcceptLanguage.intersection("da, en-gb;q=0.8, en;q=0.7", :ja, :ro, :da) # => :da
AcceptLanguage.intersection("da, en-gb;q=0.8, en;q=0.7", :ja, :ro)      # => nil
AcceptLanguage.intersection("fr-CH", :fr, two_letter_truncate: false)   # => nil
AcceptLanguage.intersection("fr-CH", :fr, two_letter_truncate: true)    # => :fr
AcceptLanguage.intersection("de, zh;q=0.4, fr;q=0", :fr)                # => nil
AcceptLanguage.intersection("de, zh;q=0.4, *;q=0.5, fr;q=0", :fr)       # => nil
AcceptLanguage.intersection("de, zh;q=0.4, *;q=0.5, fr;q=0", :ar)       # => :ar
```

### Rails integration example

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :best_locale_from_request!

  def best_locale_from_request!
    I18n.locale = best_locale_from_request
  end

  def best_locale_from_request
    return I18n.default_locale unless request.headers.key?("HTTP_ACCEPT_LANGUAGE")

    string = request.headers.fetch("HTTP_ACCEPT_LANGUAGE")
    locale = AcceptLanguage.intersection(string, I18n.default_locale, *I18n.available_locales)

    # If the server cannot serve any matching language,
    # it can theoretically send back a 406 (Not Acceptable) error code.
    # But, for a better user experience, this is rarely done and more
    # common way is to ignore the Accept-Language header in this case.
    return I18n.default_locale if locale.nil?

    locale
  end
end
```

## Versioning

__AcceptLanguage__ uses [Semantic Versioning 2.0.0](https://semver.org/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
