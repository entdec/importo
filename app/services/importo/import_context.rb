# frozen_string_literal: true

module Importo
  class ImportContext < ApplicationContext
    attribute :import, type: Import, typecaster: ->(value) { value.is_a?(Import) ? value : Import.find(value) }
    attribute :checked_columns, type: Array, typecaster: ->(value) { value.is_a?(Array) ? value : [] }
  end
end
