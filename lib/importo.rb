# frozen_string_literal: true

require 'importo/engine'

module Importo
  class Error < StandardError; end

  class Configuration
    attr_writer :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
    end

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end

  class << self
    attr_reader :config

    def configure
      @config = Configuration.new
      yield config
    end
  end
end
