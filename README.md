# AcceptLanguage

A lightweight, thread-safe Ruby library for parsing the `Accept-Language` HTTP header field.

This implementation conforms to:

- [RFC 7231 Section 5.3.5](https://www.rfc-editor.org/rfc/rfc7231#section-5.3.5) — Accept-Language header field definition
- [RFC 7231 Section 5.3.1](https://www.rfc-editor.org/rfc/rfc7231#section-5.3.1) — Quality values syntax
- [RFC 4647 Section 3.3.1](https://www.rfc-editor.org/rfc/rfc4647#section-3.3.1) — Basic Filtering matching scheme
- [BCP 47](https://www.rfc-editor.org/info/bcp47) — Tags for Identifying Languages

> [!NOTE]
> RFC 7231 obsoletes [RFC 2616](https://www.rfc-editor.org/rfc/rfc2616) (the original HTTP/1.1 specification). The `Accept-Language` header behavior defined in RFC 2616 Section 14.4 remains unchanged in RFC 7231, ensuring full backward compatibility.

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

Quality values (q-values) indicate relative preference, ranging from `0` (not acceptable) to `1` (most preferred). When omitted, the default is `1`.

Per RFC 7231 Section 5.3.1, valid q-values have at most three decimal places: `0`, `0.7`, `0.85`, `1.000`. Invalid q-values cause the associated language range to be ignored.

```ruby
parser = AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7")

parser.match(:en, :da)      # => :da       (q=1 beats q=0.8)
parser.match(:en, :"en-GB") # => :"en-GB"  (q=0.8 beats q=0.7)
parser.match(:ja)           # => nil       (no match)
```

### Declaration order

When multiple languages share the same q-value, declaration order in the header determines priority—the first declared language wins:

```ruby
AcceptLanguage.parse("en;q=0.8, fr;q=0.8").match(:en, :fr)
# => :en  (declared first)

AcceptLanguage.parse("fr;q=0.8, en;q=0.8").match(:en, :fr)
# => :fr  (declared first)
```

### Basic Filtering

This library implements the Basic Filtering matching scheme defined in RFC 4647 Section 3.3.1. A language range matches a language tag if, in a case-insensitive comparison, it exactly equals the tag, or if it exactly equals a prefix of the tag such that the first character following the prefix is `-`.

```ruby
AcceptLanguage.parse("de-de").match(:"de-DE-1996")
# => :"de-DE-1996"  (prefix match)

AcceptLanguage.parse("de-de").match(:"de-Deva")
# => nil  ("de-de" is not a prefix of "de-Deva")

AcceptLanguage.parse("de-de").match(:"de-Latn-DE")
# => nil  ("de-de" is not a prefix of "de-Latn-DE")
```

Prefix matching respects hyphen boundaries:

```ruby
AcceptLanguage.parse("zh").match(:"zh-TW")
# => :"zh-TW"  ("zh" matches "zh-TW")

AcceptLanguage.parse("zh").match(:zhx)
# => nil  ("zh" does not match "zhx" — different language code)

AcceptLanguage.parse("zh-TW").match(:zh)
# => nil  (more specific range does not match less specific tag)
```

### Wildcards

The wildcard `*` matches any language not matched by another range in the header. This behavior is specific to HTTP, as noted in RFC 4647 Section 3.3.1.

```ruby
AcceptLanguage.parse("de, *;q=0.5").match(:ja)
# => :ja  (matched by wildcard)

AcceptLanguage.parse("de, *;q=0.5").match(:de, :ja)
# => :de  (explicit match takes precedence)
```

### Exclusions

A q-value of `0` explicitly marks a language as not acceptable:

```ruby
AcceptLanguage.parse("*, en;q=0").match(:en)
# => nil  (English explicitly excluded)

AcceptLanguage.parse("*, en;q=0").match(:ja)
# => :ja  (Japanese matched by wildcard)
```

Exclusions apply via prefix matching:

```ruby
AcceptLanguage.parse("*, en;q=0").match(:"en-GB")
# => nil  (en-GB excluded via "en" prefix)
```

### Case insensitivity

Matching is case-insensitive per RFC 4647 Section 2, but the original case of available language tags is preserved in the return value:

```ruby
AcceptLanguage.parse("EN-GB").match(:"en-gb")
# => :"en-gb"

AcceptLanguage.parse("en-gb").match(:"EN-GB")
# => :"EN-GB"
```

### BCP 47 language tags

Full support for BCP 47 language tags including script subtags, region subtags, and variant subtags:

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

## Standards compliance

### Supported specifications

| Specification | Description | Status |
|---------------|-------------|--------|
| RFC 7231 §5.3.5 | Accept-Language header field | ✅ Supported |
| RFC 7231 §5.3.1 | Quality values (qvalues) | ✅ Supported |
| RFC 4647 §2.1 | Basic Language Range syntax | ✅ Supported |
| RFC 4647 §3.3.1 | Basic Filtering scheme | ✅ Supported |
| BCP 47 | Language tag structure | ✅ Supported |

### Not implemented

| Specification | Description | Reason |
|---------------|-------------|--------|
| RFC 4647 §2.2 | Extended Language Range | Not used by HTTP |
| RFC 4647 §3.3.2 | Extended Filtering | Not used by HTTP |
| RFC 4647 §3.4 | Lookup scheme | Design choice — Basic Filtering is appropriate for HTTP content negotiation |

## Documentation

- [API documentation](https://rubydoc.info/github/cyril/accept_language.rb/main)
- [RFC 7231 — HTTP/1.1 Semantics and Content](https://www.rfc-editor.org/rfc/rfc7231)
- [RFC 4647 — Matching of Language Tags](https://www.rfc-editor.org/rfc/rfc4647)
- [BCP 47 — Tags for Identifying Languages](https://www.rfc-editor.org/info/bcp47)

## Versioning

This library follows [Semantic Versioning 2.0](https://semver.org/).

## License

Available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
