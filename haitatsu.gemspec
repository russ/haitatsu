# -*- encoding: utf-8 -*-
require File.expand_path("../lib/haitatsu/version", __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Russ Smith"]
  gem.email         = ["russ@bashme.org"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "haitatsu"
  gem.require_paths = ["lib"]
  gem.version       = Haitatsu::VERSION

  gem.add_dependency("commander")
  gem.add_dependency("grit")
  gem.add_dependency("net-ssh")

  gem.add_development_dependency("rake")
  gem.add_development_dependency("rspec", "~> 2.5")
  gem.add_development_dependency("yard")
end
