module Importo
  class ImportJobCallback
    include Rails.application.routes.url_helpers

    def on_complete(_status, options)
      options = options.deep_stringify_keys
      import = Import.find(options["import_id"])
      if import.present?
        results_file = import.importer.results_file
        if results_file.is_a?(StringIO)
          import.result.attach(io: results_file, filename: import.importer.file_name("results"),
                               content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        else
          import.result.attach(io: File.open(results_file), filename: import.importer.file_name("results"),
                               content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        end

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
  end
end
