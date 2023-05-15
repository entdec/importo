class User < ApplicationRecord
  include Importo::ActsAsImportOwner
  signalable
  
  def current!
    Thread.current[:user] = self
  end

  class << self
    def current
      Thread.current[:user]
    end

    def reset_current!
      Thread.current[:user] = nil
    end
  end
end