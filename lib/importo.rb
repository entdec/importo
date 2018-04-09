# frozen_string_literal: true

require 'importo/engine'

module Importo
  class Error < StandardError; end

  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_writer   :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @base_controller = '::ApplicationController'
    end

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end
  end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end
  end
end
