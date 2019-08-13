
# frozen_string_literal: true

require 'active_support/concern'

module Revertable
  extend ActiveSupport::Concern

  def revert!
    revertable_results = import.results.select { |result| result['state'] == 'success' }

    revertable_results.each do |revertable_result|
      next unless revertable_result['state'] == 'success'

      begin
        undo(revertable_result['class'], revertable_result['id'], cells_from_row(revertable_result['row']))
        revertable_result['state'] = 'reverted'
        revertable_result.delete('message')
        revertable_result.delete('errors')
      rescue StandardError => e
        result['message'] = "Not reverted: #{e.message}"
      end
    end

    @import.result.attach(io: results_file, filename: 'results.xlsx', content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    @import.result_message += "\nReverted #{results.select { |result| result['state'] == 'reverted' }.size} of #{revertable_results.size} rows"
    @import.reverted!
  rescue StandardError => e
    @import.result_message = "Exception: #{e.message}"
    Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(';')}"
    @import.failure!
  end


  private

  def undo(klass, id, _row)
    klass.constantize.find(id).destroy
  end
end
