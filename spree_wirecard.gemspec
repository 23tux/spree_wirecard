# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_wirecard'
  s.version     = '0.0.1'
  s.summary     = 'Spree Extenstion for Wirecard'
  s.description = 'Payment Method for Wirecard Transactions for Spree'
  s.required_ruby_version = '>= 1.8.7'

  s.authors     = ['Clemens Kofler']
  s.email       = 'clemens@railway.at'
  s.homepage    = 'https://github.com/clemens/spree_wirecard'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '>=1.0.0')
  s.add_development_dependency 'rspec-rails'
end
