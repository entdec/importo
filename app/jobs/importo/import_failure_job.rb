# frozen_string_literal: true

require_dependency 'importo/application_job'

module Importo
  class ImportFailureJob < ApplicationJob
    queue_as :import

    def perform(import_id)
      imprt = Import.find(import_id)
      imprt.user.channel.current!
      # Send email
    end
  end
end
