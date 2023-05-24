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

`Accept Language` library is primarily designed to assist web servers in serving multilingual content based on user preferences expressed in the `Accept-Language` header. This library finds the best matching language from the available languages your application supports and the languages the user prefers.

Below are some examples of how you might use the library:

```ruby
# The user prefers Danish, then British English, and finally any kind of English.
# Since your application supports English and Danish, it selects Danish as it's the user's first choice.
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:en, :da) # => :da

# The user prefers Danish, then English, and finally Uyghur. Your application supports British English and Chinese Uyghur.
# Here, the library will return Chinese Uyghur because it's the highest ranked language in the user's list that your application supports.
AcceptLanguage.parse("da, en;q=0.8, ug;q=0.9").match("en-GB", "ug-CN") # => "ug-CN"

# The user prefers Danish, then British English, and finally any kind of English. Your application only supports Japanese.
# Since none of the user's preferred languages are supported, it returns nil.
AcceptLanguage.parse("da, en-GB;q=0.8, en;q=0.7").match(:ja) # => nil

# The user only accepts Swiss French, but your application only supports French. Since Swiss French and French are not the same, it returns nil.
AcceptLanguage.parse("fr-CH").match(:fr) # => nil

# The user prefers German, then any language except French. Your application supports French.
# Even though the user specified a wildcard, they explicitly excluded French. Therefore, it returns nil.
AcceptLanguage.parse("de, zh;q=0.4, *;q=0.5, fr;q=0").match(:fr) # => nil

# The user prefers Uyghur (in Latin script, as used in Uzbekistan). Your application supports this exact variant of Uyghur.
# Since the user's first choice matches a language your application supports, it returns that language.
AcceptLanguage.parse("uz-latn-uz").match("uz-Latn-UZ") # => "uz-Latn-UZ"

# The user doesn't mind what language they get, but they'd prefer not to have English. Your application supports English.
# Even though the user specified a wildcard, they explicitly excluded English. Therefore, it returns nil.
AcceptLanguage.parse("*, en;q=0").match("en") # => nil
```

These examples show the flexibility and power of `Accept Language`. By giving your application a deep understanding of the user's language preferences, `Accept Language` can significantly improve user satisfaction and engagement with your application.

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

## Read more

- [Language negotiation with Ruby](https://dev.to/cyri_/language-negotiation-with-ruby-5166)
- [Rubyで言語ネゴシエーション](https://qiita.com/cyril/items/45dc233edb7be9d614e7)

## Versioning

__AcceptLanguage__ uses [Semantic Versioning 2.0.0](https://semver.org/)

## License

The [gem](https://rubygems.org/gems/accept_language) is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
