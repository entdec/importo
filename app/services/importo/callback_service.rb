# frozen_string_literal: true

module Importo
  class CallbackService < ApplicationService
    context do
      attribute :import, type: Import, typecaster: ->(value) { value.is_a?(Import) ? value : Import.find(value) }
      attribute :callback
    end

    def perform
      Importo.config.import_callback(context.import, context.callback.to_sym)
    end
  end
end
