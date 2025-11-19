# frozen_string_literal: true

source "https://rubygems.org"
git_source(:entdec) { |repo_name| "git@github.com:entdec/#{repo_name}.git" }

# Declare your gem's dependencies in importo.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem "servitium", "~> 1.1"
gem "signum", "~> 0.3"
gem "sidekiq-batch", entdec: "sidekiq-batch", branch: "master"
gem "facio", entdec: "facio", branch: "main"
gem "satis", "~> 2", entdec: "satis", branch: "develop"
gem "sprockets-rails"
gem "facio", "~> 0.1"
gem "good_job", "~> 3.29"
gem "csv", "~> 3.0"
