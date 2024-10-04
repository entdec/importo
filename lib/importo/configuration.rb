# frozen_string_literal: true

module Importo
  module Options
    module ClassMethods
      def option(name, default: nil, proc: false)
        attr_writer(name)
        schema[name] = {default: default, proc: proc}
        if schema[name][:proc]
          define_method(name) do |*params|
            value = instance_variable_get(:"@#{name}")
            instance_exec(*params, &value)
          end
        else
          define_method(name) do
            instance_variable_get(:"@#{name}")
          end
        end
      end

      def schema
        @schema ||= {}
      end
    end

    def set_defaults!
      self.class.schema.each do |name, options|
        instance_variable_set(:"@#{name}", options[:default])
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
      end)

    # You can either use GoodJob::Batch or Importo::SidekiqBatchAdapter
    option :batch_adapter, default: lambda { Importo::SidekiqBatchAdapter }, proc: true
    option :import_job_base_class, default: "Object"

    # Extra links relevant for this import: { link_name: { icon: 'far fa-..', url: '...' } }
    option(:admin_extra_links,
      default: lambda do |import|
        []
      end)

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
    alias_method :setup, :configure

    def reset_config!
      @config = Configuration.new
    end
  end
end
