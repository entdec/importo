# frozen_string_literal: true

module Importo
  class ImportService < ApplicationService
    def perform
      context.import.import!
      context.import.importer.import!
    rescue
      context.import.failure!
      context.fail!
    end
  end
end
