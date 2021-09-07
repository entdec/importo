# frozen_string_literal: true

module Importo
  class ImportService < ApplicationService
    def perform
      sleep 1

      context.import.import!
      context.import.importer.import!
    rescue StandardError
      context.import.failure!
      context.fail!
    end
  end
end
