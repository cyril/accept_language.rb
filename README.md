# Accept Language 🌐

Web applications often need to cater to users from around the world. One of the ways they can provide a better user experience is by presenting the content in the user's preferred language. This is where the `Accept-Language` HTTP header comes into play. Sent by the client (usually a web browser), this header tells the server the list of languages the user understands, and the user's preference order.

Parsing the `Accept-Language` header can be complex due to its flexible format defined in [RFC 2616](https://tools.ietf.org/html/rfc2616#section-14.4). For instance, it can specify languages, countries, and scripts with varying degrees of preference (quality values).

`Accept Language` is a lightweight, thread-safe Ruby library designed to parse the `Accept-Language` header, making it easier for your application to determine the best language to respond with. It calculates the intersection of the languages the user prefers and the languages your application supports, handling all the complexity of quality values and wildcards.

Whether you're building a multilingual web application or just trying to make your service more accessible to users worldwide, `Accept Language` offers a reliable, simple solution.

## Status

[![Version](https://img.shields.io/github/v/tag/cyril/accept_language.rb?label=Version&logo=github)](https://github.com/cyril/accept_language.rb/tags)
[![Yard documentation](https://img.shields.io/badge/Yard-documentation-blue.svg?logo=github)](https://rubydoc.info/github/cyril/accept_language.rb/main)
[![Ruby](https://github.com/cyril/accept_language.rb/workflows/Ruby/badge.svg?branch=main)](https://github.com/cyril/accept_language.rb/actions?query=workflow%3Aruby+branch%3Amain)
[![RuboCop](https://github.com/cyril/accept_language.rb/workflows/RuboCop/badge.svg?branch=main)](https://github.com/cyril/accept_language.rb/actions?query=workflow%3Arubocop+branch%3Amain)
[![License](https://img.shields.io/github/license/cyril/accept_language.rb?label=License&logo=github)](https://github.com/cyril/accept_language.rb/raw/main/LICENSE.md)

## Why Choose Accept Language?

There are a myriad of tools out there, so why should you consider Accept Language for your next project? Here's why:

- **Thread-Safe**: Multithreading can present unique challenges when dealing with shared resources. Our implementation is designed to be thread-safe, preventing potential concurrency issues.
- **Compact and Robust**: Despite being small in size, Accept Language can handle even the trickiest cases with grace, ensuring you have a reliable tool at your disposal.
- **Case-Insensitive Matching**: In line with the principle of robustness, our tool matches both strings and symbols regardless of case, providing greater flexibility.
- **Independent of Framework**: While many tools require Rails, Rack, or i18n to function, Accept Language stands on its own. It works perfectly well without these dependencies, increasing its adaptability.
- **BCP 47 Support**: BCP 47 defines a standard for language tags. This is crucial for specifying languages unambiguously. Accept Language complies with this standard, ensuring accurate language identification.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "accept_language"
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install accept_language
```

## Usage

The `Accept Language` library helps web applications serve content in the user's preferred language by parsing the `Accept-Language` HTTP header. This header indicates the user's language preferences and their priority order.

### Basic Syntax

The library has two main methods:

- `AcceptLanguage.parse(header)`: Parses the Accept-Language header
- `match(*available_languages)`: Matches against the languages your application supports

```ruby
AcceptLanguage.parse("fr-CH, fr;q=0.9").match(:fr, :"fr-CH") # => :"fr-CH"
```

### Understanding Language Preferences

#### Simple Language Matching

```ruby
# Header: "da" (Danish is the preferred language)
# Available: :en and :da
AcceptLanguage.parse("da").match(:en, :da) # => :da

# No match available - returns nil
AcceptLanguage.parse("da").match(:fr, :en) # => nil
```

#### Quality Values (q-values)

Q-values range from 0 to 1 and indicate preference order:

```ruby
# Header: "da, en-GB;q=0.8, en;q=0.7"
# Means:
#   - Danish (da): q=1.0 (highest priority)
#   - British English (en-GB): q=0.8 (second choice)
#   - Generic English (en): q=0.7 (third choice)
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da) # => :da
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :"en-GB") # => :"en-GB"
```

#### Language Variants

The library handles specific language variants (regional or script variations):

```ruby
# Specific variants must match exactly
AcceptLanguage.parse("fr-CH").match(:fr) # => nil (Swiss French ≠ Generic French)

# But generic variants can match specific ones
AcceptLanguage.parse("fr").match(:"fr-CH") # => :"fr-CH"

# Script variants are also supported
AcceptLanguage.parse("uz-Latn-UZ").match("uz-Latn-UZ") # => "uz-Latn-UZ"
```

#### Wildcards and Exclusions

The `*` wildcard matches any language, and `q=0` excludes languages:

```ruby
# Accept any language but prefer German
AcceptLanguage.parse("de-DE, *;q=0.5").match(:fr) # => :fr (matched by wildcard)

# Accept any language EXCEPT English
AcceptLanguage.parse("*, en;q=0").match(:en) # => nil (explicitly excluded)
AcceptLanguage.parse("*, en;q=0").match(:fr) # => :fr (matched by wildcard)
```

#### Complex Example

```ruby
# Header: "de-LU, fr;q=0.9, en;q=0.7, *;q=0.5"
# Means:
#   - Luxembourg German: q=1.0 (highest priority)
#   - French: q=0.9 (second choice)
#   - English: q=0.7 (third choice)
#   - Any other language: q=0.5 (lowest priority)
header = "de-LU, fr;q=0.9, en;q=0.7, *;q=0.5"
parser = AcceptLanguage.parse(header)

parser.match(:de, :"de-LU") # => :"de-LU" (exact match)
parser.match(:fr, :en)      # => :fr (higher q-value)
parser.match(:es, :it)      # => :es (matched by wildcard)
```

### Case Sensitivity

The matching is case-insensitive but preserves the case of the returned value:

```ruby
AcceptLanguage.parse("en-GB").match("en-gb") # => "en-gb"
AcceptLanguage.parse("en-gb").match("en-GB") # => "en-GB"
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

## Read more

- [Language negotiation with Ruby](https://dev.to/cyri_/language-negotiation-with-ruby-5166)
- [Rubyで言語ネゴシエーション](https://qiita.com/cyril/items/45dc233edb7be9d614e7)

## Versioning

__AcceptLanguage__ uses [Semantic Versioning 2.0.0](https://semver.org/)

## License

The [gem](https://rubygems.org/gems/accept_language) is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
