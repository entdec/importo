# frozen_string_literal: true

require_dependency 'importo/application_job'

module Importo
  class RevertJob < ApplicationJob
    queue_as Importo.config.queue_name

    def perform(import_id)
      sleep 1
      imprt = Import.find(import_id)
      # Actually start the revert, this can not be started in after_transition any => :importing because of nested transaction horribleness.
      imprt.importer.revert!
    rescue StandardError
      imprt&.failure!
      raise
    end
  end
end
