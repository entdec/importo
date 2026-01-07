# frozen_string_literal: true

require "axlsx"
require "roo"
require "roo-xls"
require "slim"
require "state_machines-activerecord"
require "signum"
require "turbo-rails"
require "view_component"
require "with_advisory_lock"

module Importo
  class Engine < ::Rails::Engine
    isolate_namespace Importo

    initializer "importo.active_storage.attached" do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Importo::Import.include(ImportHelpers)

          # For now put this here to ensure compatibility
          # require "importo/adapters/sidekiq_batch_adapter"
        end
      end
    end
  end
end
