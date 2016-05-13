# webflow_cap

This gem is a plugin for [capistrano 3](http://capistranorb.com/) to make deployment of rails applications to [.webflow](http://www.webflow.de) servers easy.

Applications that get deployed with the capistrano tasks are automatically configured and setup to run supervised.
The database.yml is automatically created and configured to use the right connection settings.
An application specific database will also be created.

The application server (which defaults to [passenger standalone](https://www.phusionpassenger.com/#about)) will be started and supervised by [runit](http://smarden.org/runit/).

## Usage

1. Add the following lines to your Gemfile:

   ```ruby
   gem 'puma'
   
   group :development do
     gem 'capistrano-rails'
     gem 'webflow_cap'
   end
  ```
2. Execute `bundle install` to install these gems.
3. Execute `bundle exec webflow_capify` which asks you some questions and installs capistrano templates with sane defaults to your project.
4. With these capistrano files in place all you need to do is execute `bundle exec cap production deploy` to spin up your rails application.

If you have any problems please contact us @[webflow](http://www.webflow.de)

## License

MIT; Copyright (c) 2014 Florian Aman, webflow GmbH

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
