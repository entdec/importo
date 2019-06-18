# frozen_string_literal: true

require_dependency 'importo/application_job'

module Importo
  class ImportJob < ApplicationJob
    queue_as Importo.config.queue_name

    def perform(import_id)
      sleep 1
      imprt = Import.find(import_id)
      # Set the state of the object.
      imprt.import!
      # Actually start the import, this can not be started in after_transition any => :importing because of nested transaction horribleness.
      imprt.importer.import!
    rescue StandardError => e
      imprt&.failure!
      raise
    end
  end
end
