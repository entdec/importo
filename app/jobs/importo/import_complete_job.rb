# frozen_string_literal: true

require_dependency 'importo/application_job'

module Importo
  class ImportCompleteJob < ApplicationJob
    queue_as :import

    def perform(import_id)
      sleep 1
      @imprt = Import.find(import_id)
      @imprt.user.channel.current!
      result_xml = @imprt.importer.results_file

      # Send email
      MessageJob.perform_now(@imprt, 'complete', attachments: [{ content: result_xml, content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', file_name: 'import_results.xlsx', auto_zip: false }])
    end
  end
end
