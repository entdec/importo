module Importo
  class ImportJobCallback < ActiveJob::Base
    include Sidekiq::Batch::Callback if Importo.sidekiq?
    include Rails.application.routes.url_helpers

    # This is for good_job
    def perform(batch, context)
      import = Import.find(batch.properties[:import_id])
      complete_import(import)
    end

    def complete_import(import)
      return if import.blank?

      # Sidekiq's batch :complete event can fire as soon as every row has been
      # attempted once, even though some rows failed and are still awaiting a
      # retry. Bail out here so we don't finalize (and report a wrong count)
      # before every row has actually finished processing.
      return unless import.results.count == import.importer.send(:row_count)

      results_file = import.importer.results_file
      results_file = results_file.is_a?(StringIO) ? results_file : File.open(results_file)

      import.result.attach(io: results_file, filename: import.importer.file_name("results"),
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")

      ActiveRecord::Base.uncached do
        import.result_message = I18n.t("importo.importers.result_message",
          nr: import.results.where("details @> ?", {state: "success"}.to_json).count, of: import.importer.send(:row_count))
      end

      if import.can_complete?
        import.complete!
      else
        import.save!
      end
    end

    # This is for sidekiq
    def on_complete(status, options)
      options = options.deep_stringify_keys
      import = Import.find(options["import_id"])
      complete_import(import)
    end

    # Sidekiq's batch :success event only fires once every job (including
    # retries) has truly succeeded, so it is the reliable place to finalize.
    alias_method :on_success, :on_complete
  end
end
