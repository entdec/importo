module Importo
  class ImportJobCallback < ActiveJob::Base
    include Sidekiq::Batch::Callback
    include Rails.application.routes.url_helpers

    def perform(batch, params)
      import = Import.find(batch.properties[:import_id])
      complete_import(import)
    end

    def complete_import(import)
      if import.present?
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
    end

    def on_complete(status, options)
      options = options.deep_stringify_keys
      import = Import.find(options["import_id"])
      complete_import(import)
    end

  end
end
