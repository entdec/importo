# frozen_string_literal: true

class ImportJob < ApplicationJob
  queue_as :import

  def perform(import_id)
    sleep 1
    imprt = Import.find(import_id)
    imprt.user.current!
    imprt.user.channel.current!
    # Set the state of the object.
    imprt.import!
    # Actually start the import, this can not be started in after_transition any => :importing because of nested transaction horribleness.
    imprt.importer.import!
  end
end
