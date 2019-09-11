
# frozen_string_literal: true

require 'active_support/concern'

module Revertable
  extend ActiveSupport::Concern

  def revert!
    undo_all

    import.reverted!
  rescue StandardError => e
    import.result_message = "Exception: #{e.message}"
    Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(';')}"
    import.failure!
  end

  private

  def undo_all
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
  end

  def undo_row(klass, id, _row)
    klass.constantize.find(id).destroy
  end
end
