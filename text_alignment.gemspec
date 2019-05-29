lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'text_alignment/version'

Gem::Specification.new do |gem|
  gem.name          = 'text_alignment'
  gem.version       = TextAlignment::VERSION
  gem.authors       = ['Jin-Dong Kim']
  gem.email         = ['jdkim@dbcls.rois.ac.jp']
  gem.description   = %q{A ruby class that allows for computing the alignment
                         of two character strings and annotations made to them.}
  gem.summary       = 'Ruby class for aligning two character strings'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'ruby-dictionary', '~>1.1', '>=1.1.1'
  gem.add_development_dependency 'rspec', '~>3.0'
end
