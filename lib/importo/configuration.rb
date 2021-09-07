# frozen_string_literal: true

module Importo
  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_accessor :base_service
    attr_accessor :base_service_context
    attr_accessor :queue_name

    attr_writer :logger
    attr_writer :current_import_owner
    attr_writer :import_callbacks
    attr_writer :admin_visible_imports
    attr_writer :admin_can_destroy
    attr_writer :admin_extra_links

    def initialize
      @logger               = Logger.new(STDOUT)
      @logger.level         = Logger::INFO
      @base_controller      = '::ApplicationController'
      @base_service         = '::ApplicationService'
      @base_service_context = '::ApplicationContext'
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

      @admin_visible_imports = -> { Importo::Import.where(importo_ownable: current_import_owner) }
      @admin_can_destroy = ->(_import) { false }

      # Extra links relevant for this import: { link_name: { icon: 'far fa-..', url: '...' } }
      @admin_extra_links = ->(_import) { }
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

    def admin_visible_imports
      instance_exec(&@admin_visible_imports) if @admin_visible_imports
    end

    def admin_can_destroy(import)
      instance_exec(import, &@admin_can_destroy) if @admin_can_destroy
    end

    def admin_extra_links(import)
      instance_exec(import, &@admin_extra_links) if @admin_extra_links
    end
  end
end
