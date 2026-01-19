# AcceptLanguage

A lightweight, thread-safe Ruby library for parsing `Accept-Language` HTTP headers as defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4), with full support for [BCP 47](https://tools.ietf.org/html/bcp47) language tags.

[![Version](https://img.shields.io/github/v/tag/cyril/accept_language.rb?label=Version&logo=github)](https://github.com/cyril/accept_language.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/cyril/accept_language.rb/main)
![Ruby](https://github.com/cyril/accept_language.rb/actions/workflows/ruby.yml/badge.svg?branch=main)
![RuboCop](https://github.com/cyril/accept_language.rb/actions/workflows/rubocop.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/cyril/accept_language.rb?label=License&logo=github)](https://github.com/cyril/accept_language.rb/raw/main/LICENSE.md)

## Features

- Thread-safe
- No framework dependencies
- Case-insensitive matching
- BCP 47 language tag support
- Wildcard and exclusion handling

## Installation

```ruby
gem "accept_language"
```

## Usage

```ruby
AcceptLanguage.parse("en-GB, en;q=0.9").match(:en, :"en-GB")
# => :"en-GB"
```

### Quality values

Quality values (q-values) indicate preference order from 0 to 1:

```ruby
parser = AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")

parser.match(:en, :da)      # => :da
parser.match(:en, :"en-GB") # => :"en-GB"
parser.match(:fr)           # => nil
```

### Language variants

A generic language tag matches its regional variants, but not the reverse:

```ruby
AcceptLanguage.parse("fr").match(:"fr-CH")    # => :"fr-CH"
AcceptLanguage.parse("fr-CH").match(:fr)      # => nil
```

### Wildcards and exclusions

The wildcard `*` matches any language. A q-value of 0 explicitly excludes a language:

```ruby
AcceptLanguage.parse("de-DE, *;q=0.5").match(:fr)  # => :fr
AcceptLanguage.parse("*, en;q=0").match(:en)       # => nil
AcceptLanguage.parse("*, en;q=0").match(:fr)       # => :fr
```

### Case sensitivity

Matching is case-insensitive but preserves the case of the available language tag:

```ruby
AcceptLanguage.parse("en-GB").match("en-gb") # => "en-gb"
AcceptLanguage.parse("en-gb").match("en-GB") # => "en-GB"
```

### BCP 47 support

This library supports [BCP 47](https://tools.ietf.org/html/bcp47) language tags, including:

- **Script subtags**: `zh-Hans` (Simplified Chinese), `zh-Hant` (Traditional Chinese)
- **Region subtags**: `en-US`, `pt-BR`
- **Variant subtags**: `sl-nedis` (Slovenian Nadiza dialect), `de-1996` (German orthography reform)

```ruby
# Script variants
AcceptLanguage.parse("zh-Hans").match(:"zh-Hans-CN", :"zh-Hant-TW")
# => :"zh-Hans-CN"

# Orthography variants (numeric subtags)
AcceptLanguage.parse("de-1996, de;q=0.9").match(:"de-CH-1996", :"de-CH")
# => :"de-CH-1996"
```

## Rails integration

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :best_locale_from_request!

  def best_locale_from_request!
    I18n.locale = best_locale_from_request
  end

  def best_locale_from_request
    # HTTP_ACCEPT_LANGUAGE is the standardized key for the Accept-Language header in Rack/Rails
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

## Documentation

- [API Documentation](https://rubydoc.info/github/cyril/accept_language.rb/main)
- [Language negotiation with Ruby](https://dev.to/cyri_/language-negotiation-with-ruby-5166)
- [Rubyで言語ネゴシエーション](https://qiita.com/cyril/items/45dc233edb7be9d614e7)

## Versioning

This library follows [Semantic Versioning 2.0.0](https://semver.org/).

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
