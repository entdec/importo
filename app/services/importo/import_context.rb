# frozen_string_literal: true

module Importo
  class ImportContext < ApplicationContext
    input do
      attribute :import, type: Import, typecaster: ->(value) { value.is_a?(Import) ? value : Import.find(value) }
    end
  end
end
