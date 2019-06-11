# Accept Language

A tiny library for parsing the `Accept-Language` header from browsers (as defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4)).

## Status

[![Gem Version](https://badge.fury.io/rb/accept_language.svg)](https://badge.fury.io/rb/accept_language)
[![TravisCI](https://travis-ci.org/cyril/accept_language.rb.svg?branch=master)](https://travis-ci.org/cyril/accept_language.rb)
[![Inline Docs](https://inch-ci.org/github/cyril/accept_language.rb.svg)](https://inch-ci.org/github/cyril/accept_language.rb)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'accept_language'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install accept_language

## Usage

It's intended to be used in a Web server that supports some level of internationalization (i18n), but can be used anytime an `Accept-Language` header string is available.

### Examples

```ruby
AcceptLanguage.parse('da, en-gb;q=0.8, en;q=0.7') # => [:da, :"en-gb", :en]
AcceptLanguage.parse('fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5') # => [:"fr-CH", :fr, :en, :de, :*]
```

In order to help facilitate better i18n, a method is provided to return the intersection of the languages the user prefers and the languages your application supports.

### Examples

```ruby
AcceptLanguage.intersection('da, en-gb;q=0.8, en;q=0.7', :ar, :da, :ja, :ro) # => :da
AcceptLanguage.intersection('da, en-gb;q=0.8, en;q=0.7', :ar, :ja, :ro) # => nil
AcceptLanguage.intersection('fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5', :en, :ja) # => :en
AcceptLanguage.intersection('fr-CH, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5', :ja) # => :ja
AcceptLanguage.intersection('ko, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5', :fr, :de) # => :fr
AcceptLanguage.intersection('ko, fr-CH;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5', :fr, :de, truncate: false) # => :de
AcceptLanguage.intersection('*;q=0.5, zh;q=0.4', :ja, :zh) # => :ja
AcceptLanguage.intersection('fr;q=0, zh;q=0.4', :fr) # => nil
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cyril/accept_language.rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Versioning

__AcceptLanguage__ uses [Semantic Versioning 2.0.0](https://semver.org/)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AcceptLanguage project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cyril/accept_language.rb/blob/master/CODE_OF_CONDUCT.md).
