# frozen_string_literal: true

module Importo
  class CallbackService < ApplicationService
    context do
      attribute :import
      attribute :callback
    end

    def perform
      Importo.config.import_callback(context.import, context.callback)
    end
  end
end
