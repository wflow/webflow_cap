# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Florian Aman"]
  gem.license       = 'MIT'
  gem.email         = ["fa@webflow.de"]
  gem.description   = %q{Deploy Rails apps}
  gem.summary       = %q{webflow_cap is used to deploy Ruby on Rails Applications}
  gem.homepage      = "https://rubygems.org/gems/webflow_cap"

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "webflow_cap"
  gem.require_paths = ["lib"]
  gem.version       = "0.2.2"
  
  # dependencies
  gem.add_dependency 'capistrano',         '~>3.2'
  gem.add_dependency 'capistrano-bundler', '~>1.1'
end
