# frozen_string_literal: true

module Importo
  class Engine < ::Rails::Engine
    isolate_namespace Importo

    initializer 'active_storage.attached' do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Importo::Import.include(ImportHelpers)
        end
      end
    end

    initializer 'importo.append_migrations' do |app|
      unless app.root.to_s.match?(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
