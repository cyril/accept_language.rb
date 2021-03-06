# Accept Language 🌐

A tiny library for parsing the `Accept-Language` header from browsers (as defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4)).

## Status

[![Version](https://img.shields.io/github/v/tag/cyril/accept_language.rb?label=Version&logo=github)](https://github.com/cyril/accept_language.rb/releases)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/cyril/accept_language.rb/main)
[![CI](https://github.com/cyril/accept_language.rb/workflows/CI/badge.svg?branch=main)](https://github.com/cyril/accept_language.rb/actions?query=workflow%3Aci+branch%3Amain)
[![RuboCop](https://github.com/cyril/accept_language.rb/workflows/RuboCop/badge.svg?branch=main)](https://github.com/cyril/accept_language.rb/actions?query=workflow%3Arubocop+branch%3Amain)
[![License](https://img.shields.io/github/license/cyril/accept_language.rb?label=License&logo=github)](https://github.com/cyril/accept_language.rb/raw/main/LICENSE.md)

## Why this tool?

- Thread-safe implementation.
- Small algorithm that can handle tricky cases.
- Match strings and symbols ignoring the case.
- Works also well without Rails, Rack, i18n.
- Comes with [BCP 47](https://www.rfc-editor.org/bcp/bcp47.txt) support.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "accept_language"
```

And then execute:

```sh
bundle
```

Or install it yourself as:

```sh
gem install accept_language
```

## Usage

It's intended to be used in a Web server that supports some level of internationalization (i18n), but can be used anytime an `Accept-Language` header string is available.

In order to help facilitate better i18n, the lib try to find the intersection of the languages the user prefers and the languages your application supports.

Some examples:

```ruby
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da)       # => :da
AcceptLanguage.parse("da, en;q=0.8, ug;q=0.9").match("en-GB", "ug-CN")  # => "ug-CN"
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:ja)            # => nil
AcceptLanguage.parse("fr-CH").match(:fr)                                # => nil
AcceptLanguage.parse("de, zh;q=0.4, fr;q=0").match(:fr)                 # => nil
AcceptLanguage.parse("de, zh;q=0.4, *;q=0.5, fr;q=0").match(:ar)        # => :ar
AcceptLanguage.parse("uz-latn-uz").match("uz-Latn-UZ")                  # => "uz-Latn-UZ"
AcceptLanguage.parse("foo;q=0.1").match(:FoO)                           # => :FoO
AcceptLanguage.parse("foo").match("bar")                                # => nil
AcceptLanguage.parse("*").match("BaZ")                                  # => "BaZ"
AcceptLanguage.parse("*;q=0").match("foobar")                           # => nil
AcceptLanguage.parse("en, en;q=0").match("en")                          # => nil
AcceptLanguage.parse("*, en;q=0").match("en")                           # => nil
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
    locale = AcceptLanguage.parse(string).match(*I18n.available_locales)

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

The [gem](https://rubygems.org/gems/accept_language) is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
