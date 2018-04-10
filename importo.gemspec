# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

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

  s.add_dependency 'rails', '~> 5.1.3'
  s.add_dependency 'slim', '~> 3.0.8'
  s.add_dependency 'roo', '~> 2.7'
  s.add_dependency 'roo-xls', '~> 1.1'
  s.add_dependency 'axlsx', '~> 2.1.0.pre'

  s.add_development_dependency 'pg'
end
