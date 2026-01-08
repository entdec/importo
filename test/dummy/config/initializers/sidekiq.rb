Sidekiq.strict_args!(false)

if Rails.env.test?
  require "sidekiq/testing"
  Sidekiq::Testing.inline!
end

Sidekiq.configure_server do |config|
  config.redis = {url: ENV.fetch("RAILS_REDIS_URL") { "redis://redis:6379/1" }}
end

Sidekiq.configure_client do |config|
  config.redis = {url: ENV.fetch("RAILS_REDIS_URL") { "redis://redis:6379/1" }}
end
