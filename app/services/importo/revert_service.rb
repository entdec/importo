# frozen_string_literal: true

module Importo
  class RevertService < ApplicationService
    def perform
      sleep 1

      context.import.importer.revert!
    rescue
      context.import.failure!
      context.fail!
    end
  end
end
