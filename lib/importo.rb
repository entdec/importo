# frozen_string_literal: true

require 'aasm'
require 'axlsx'
require 'roo'
require 'roo-xls'
require 'slim'

require 'importo/engine'
require 'importo/acts_as_import_owner'
require 'importo/import_field'

module Importo
  class Error < StandardError; end
  class DuplicateRowError < Error; end

  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_accessor :queue_name

    attr_writer :logger
    attr_writer :current_import_owner
    attr_writer :import_callbacks

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
      @base_controller      = '::ApplicationController'
      @current_import_owner = -> {}
      @import_callbacks     = {
        importing: lambda do |_import|
        end,
        completed: lambda do |_import|
        end,
        failed:    lambda do |_import|
        end
      }
      @queue_name = :import
    end

    # Config: logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    def current_import_owner
      raise 'current_import_owner should be a Proc' unless @current_import_owner.is_a? Proc
      instance_exec(&@current_import_owner)
    end

    def import_callback(import, state)
      instance_exec(import, &@import_callbacks[state]) if @import_callbacks[state]
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
