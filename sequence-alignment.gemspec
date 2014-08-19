# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
#require 'sequence-aligner/version'

Gem::Specification.new do |gem|
  gem.name          = 'sequence-aligner'
#  gem.version       = Dictionary::VERSION
  gem.authors       = ['Jin-Dong Kim']
  gem.email         = ['jindong.kim@gmail.com']
  gem.description   = %q{A ruby class that allowst for computing the alignment
                         of two character sequences and annotations made to them.}
  gem.summary       = 'Ruby class for aligning two character sequences'
  gem.homepage      = 'https://github.com/jdkim/sequence-aligner'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'ruby-dictionary'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
