# Opal Sprockets

_Adds sprockets support for [Opal](http://opalrb.org)._

## Installation

Add to your `Gemfile`:

```ruby
gem "opal-sprockets"
```

## Usage

Sprockets uses a load path for code files, so make a simple `app/` directory
with some code inside `app/application.rb`:

```ruby
# app/application.rb

require "opal"

puts "hello, world"
```

The opal corelib and runtime can be included in your app simply by adding
`require "opal"`. We also need an html file to test the application with,
so add `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <script src="/assets/application.js"></script>
</head>
<body>
</body>
</html>
```

## Running Application

`opal-sprockets` comes with a simple `Server` class that can be used to easily
configure applications inside `config.ru`:

```ruby
# config.ru

require 'bundler'
Bundler.require

run Opal::Server.new { |s|
  s.append_path 'app'

  s.main = 'application'
}
```

This just adds the `app/` directory to the load path, and tells sprockets that
`application.rb` will be the main file to load.

Now just run the rack app:

```
$ bundle exec rackup
```

And then visit `http://127.0.0.1:9292` in any browser.

## License

(The MIT License)

Copyright (C) 2013 by Adam Beynon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
