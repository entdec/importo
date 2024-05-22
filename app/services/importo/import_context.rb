# frozen_string_literal: true

module Importo
  if defined?(Servitium) && ApplicationContext < Servitium::Context
    class ImportContext < ApplicationContext
      input do
        attribute :import, type: Import, typecaster: ->(value) { value.is_a?(Import) ? value : Import.find(value) }
      end
    end
  else
    class ImportContext < ApplicationContext
      attribute :import, :model, class_name: 'Importo::Import'
    end

  end
end
