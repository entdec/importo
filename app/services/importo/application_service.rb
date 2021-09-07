# frozen_string_literal: true

module Importo
  class ApplicationService < Importo.config.base_service.constantize
    def self.queue_name
      Importo.config.queue_name
    end
  end
end
