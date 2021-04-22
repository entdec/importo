# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'importo/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'importo'
  s.version     = Importo::VERSION
  s.authors     = ['Andre Meij', 'Tom de Grunt']
  s.email       = ['andre@itsmeij.com', 'tom@degrunt.nl']
  s.homepage    = 'https://gitlab.com/entropydecelerator/importo'
  s.summary     = 'Rails engine allowing uploads and imports'
  s.description = 'Upload xls, xlsx and csv files and import the data in rails models.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'caxlsx', '~> 3.0.1'
  s.add_dependency 'rails', '>= 5.2'
  s.add_dependency 'roo', '~> 2.7'
  s.add_dependency 'roo-xls', '~> 1.1'
  s.add_dependency 'simple_form', '> 3'
  s.add_dependency 'slim', '> 3.0'
  s.add_dependency 'state_machines-activerecord', '~> 0.5'
  s.add_dependency 'state_machines-audit_trail', '~> 2'

  s.add_development_dependency 'auxilium', '~> 0.2'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'minitest-reporters', '~> 1.1'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rails', '~> 0.3'
  s.add_development_dependency 'rubocop', '~> 0.49'
end
