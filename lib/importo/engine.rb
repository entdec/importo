# frozen_string_literal: true

module Importo
  class Engine < ::Rails::Engine
    isolate_namespace Importo

    initializer 'importo.active_storage.attached' do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Importo::Import.include(ImportHelpers)
        end
      end
    end
  end
end
