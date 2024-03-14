Sidekiq.strict_args!(false)

if Rails.env.test?
  require "sidekiq/testing"
  Sidekiq::Testing.inline!
end
