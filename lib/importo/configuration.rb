# frozen_string_literal: true

module Importo
  module Options
    module ClassMethods
      def option(name, default: nil)
        attr_accessor(name)
        schema[name] = default
      end

      def schema
        @schema ||= {}
      end
    end

    def set_defaults!
      self.class.schema.each do |name, default|
        instance_variable_set("@#{name}", default)
      end
    end

    def self.included(cls)
      cls.extend(ClassMethods)
    end
  end

  class Configuration
    include Options

    option :logger, default: Rails.logger
    option :admin_authentication_module
    option :base_controller, default: "::ApplicationController"
    option :base_service, default: "::ApplicationService"
    option :base_service_context, default: "::ApplicationContext"
    option :current_import_owner, default: lambda {}
    option :queue_name, default: :import

    option :admin_visible_imports, default: lambda { Importo::Import.where(importo_ownable: Importo.config.current_import_owner) }
    option(:admin_can_destroy,
           default: lambda do |import|
             false
           end
    )

    # Extra links relevant for this import: { link_name: { icon: 'far fa-..', url: '...' } }
    option(:admin_extra_links,
           default: lambda do |import|
             []
           end
    )

    def initialize
      set_defaults!
    end
  end

  module Configurable
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end
    alias setup configure

    def reset_config!
      @config = Configuration.new
    end
  end

end
