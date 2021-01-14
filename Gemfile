# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:entdec) { |repo_name| "git@code.entropydecelerator.com:#{repo_name}.git" }

# Declare your gem's dependencies in importo.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem 'rails', '~> 5.2.2'

gem 'auxilium', '~> 0.2', entdec: 'components/auxilium'
gem 'uikit', entdec: 'components/uikit', tag: '0.6.3'
