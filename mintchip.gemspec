# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mintchip/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Burke Libbey"]
  gem.email         = ["burke@burkelibbey.org"]
  gem.description   = %q{Ruby API wrappers for MintChip}
  gem.summary       = %q{Ruby API wrappers for MintChip.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mintchip"
  gem.require_paths = ["lib"]
  gem.version       = Mintchip::VERSION

  gem.add_dependency 'active_support'
  gem.add_dependency 'json'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'yard'
end
