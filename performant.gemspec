# -*- encoding: utf-8 -*-
require File.expand_path("../lib/performant/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Lanett"]
  gem.email         = ["mark.lanett@gmail.com"]
  gem.description   = %q{performance monitoring for background tasks}
  gem.summary       = %q{monitor the performance of all your background tasks}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "performant"
  gem.require_paths = ["lib"]
  gem.version       = Performant::VERSION

  gem.add_dependency "redis"

  gem.add_development_dependency "rspec-redis_helper"
end
