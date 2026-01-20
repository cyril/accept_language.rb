# AcceptLanguage

A lightweight, thread-safe Ruby library for parsing the `Accept-Language` HTTP header as defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4), with full support for [BCP 47](https://tools.ietf.org/html/bcp47) language tags.

[![Version](https://img.shields.io/github/v/tag/cyril/accept_language.rb?label=Version&logo=github)](https://github.com/cyril/accept_language.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/cyril/accept_language.rb/main)
![Ruby](https://github.com/cyril/accept_language.rb/actions/workflows/ruby.yml/badge.svg?branch=main)
![RuboCop](https://github.com/cyril/accept_language.rb/actions/workflows/rubocop.yml/badge.svg?branch=main)
[![License](https://img.shields.io/github/license/cyril/accept_language.rb?label=License&logo=github)](https://github.com/cyril/accept_language.rb/raw/main/LICENSE.md)

## Installation

```ruby
gem "accept_language"
```

## Usage

```ruby
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da)
# => :da
```

## Behavior

### Quality values

Quality values (q-values) express relative preference, ranging from `0` (unacceptable) to `1` (most preferred). When omitted, the default is `1`.

```ruby
parser = AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")

parser.match(:en, :da)      # => :da  (q=1 > q=0.8)
parser.match(:en, :"en-GB") # => :"en-GB"  (q=0.8 > q=0.7)
parser.match(:ja)           # => nil  (no match)
```

Per RFC 2616 Section 3.9, valid q-values have at most three decimal places: `0`, `0.7`, `0.85`, `1.000`. Invalid q-values are ignored.

### Identical quality values

When multiple languages share the same q-value, the order of declaration in the header determines priority—the first declared language is preferred:

```ruby
AcceptLanguage.parse("en;q=0.8, fr;q=0.8").match(:en, :fr)
# => :en  (declared first)

AcceptLanguage.parse("fr;q=0.8, en;q=0.8").match(:en, :fr)
# => :fr  (declared first)
```

### Prefix matching

Per RFC 2616 Section 14.4, a language-range matches any language-tag that exactly equals the range or begins with the range followed by `-`:

```ruby
AcceptLanguage.parse("zh").match(:"zh-TW")
# => :"zh-TW"  ("zh" matches "zh-TW")

AcceptLanguage.parse("zh-TW").match(:zh)
# => nil  ("zh-TW" does not match "zh")
```

Note that prefix matching follows hyphen boundaries—`zh` does not match `zhx`:

```ruby
AcceptLanguage.parse("zh").match(:zhx)
# => nil  ("zhx" is a different language code)
```

### Wildcards

The wildcard `*` matches any language not matched by another range:

```ruby
AcceptLanguage.parse("de, *;q=0.5").match(:ja)
# => :ja  (matched by wildcard)

AcceptLanguage.parse("de, *;q=0.5").match(:de, :ja)
# => :de  (explicit match preferred over wildcard)
```

### Exclusions

A q-value of `0` explicitly excludes a language:

```ruby
AcceptLanguage.parse("*, en;q=0").match(:en)
# => nil  (English excluded)

AcceptLanguage.parse("*, en;q=0").match(:ja)
# => :ja  (matched by wildcard)
```

Exclusions apply to prefix matches:

```ruby
AcceptLanguage.parse("*, en;q=0").match(:"en-GB")
# => nil  (en-GB excluded via "en" prefix)
```

### Case insensitivity

Matching is case-insensitive per RFC 2616, but the original case of available language tags is preserved:

```ruby
AcceptLanguage.parse("EN-GB").match(:"en-gb")
# => :"en-gb"

AcceptLanguage.parse("en-gb").match(:"EN-GB")
# => :"EN-GB"
```

### BCP 47 language tags

Full support for [BCP 47](https://tools.ietf.org/html/bcp47) language tags:

```ruby
# Script subtags
AcceptLanguage.parse("zh-Hant").match(:"zh-Hant-TW", :"zh-Hans-CN")
# => :"zh-Hant-TW"

# Variant subtags
AcceptLanguage.parse("de-1996, de;q=0.9").match(:"de-CH-1996", :"de-CH")
# => :"de-CH-1996"
```

## Integration examples

### Rack

```ruby
# config.ru
class LocaleMiddleware
  def initialize(app, available_locales:, default_locale:)
    @app = app
    @available_locales = available_locales
    @default_locale = default_locale
  end

  def call(env)
    locale = detect_locale(env) || @default_locale
    env["rack.locale"] = locale
    @app.call(env)
  end

  private

  def detect_locale(env)
    header = env["HTTP_ACCEPT_LANGUAGE"]
    return unless header

    AcceptLanguage.parse(header).match(*@available_locales)
  end
end
```

### Ruby on Rails

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

- [API documentation](https://rubydoc.info/github/cyril/accept_language.rb/main)
- [RFC 2616 Section 14.4](https://tools.ietf.org/html/rfc2616#section-14.4)
- [BCP 47](https://tools.ietf.org/html/bcp47)
- [Language negotiation with Ruby](https://dev.to/cyri_/language-negotiation-with-ruby-5166)
- [Rubyで言語ネゴシエーション](https://qiita.com/cyril/items/45dc233edb7be9d614e7)

## Versioning

This library follows [Semantic Versioning 2.0](https://semver.org/).

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
