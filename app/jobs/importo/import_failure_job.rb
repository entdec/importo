# frozen_string_literal: true

class ImportFailureJob < ApplicationJob
  queue_as :import

  def perform(import_id)
    imprt = Import.find(import_id)
    imprt.user.channel.current!
    # Send email
  end
end
