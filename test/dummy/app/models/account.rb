class Account < ApplicationRecord
  scribable

  def current!
    Thread.current[:account] = self
  end

  class << self
    def current
      Thread.current[:account]
    end

    def reset_current!
      Thread.current[:account] = nil
    end
  end
end
