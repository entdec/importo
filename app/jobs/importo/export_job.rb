module Importo
  class ExportJob < ApplicationJob
    CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def perform(import_id, kind)
      import = Import.find(import_id)
      import.start_export!

      importer = import.importer
      file_kind = kind.to_sym
      file = importer.public_send(:"#{file_kind}_file")

      filename = importer.file_name(file_kind)
      import.result.attach(io: file, filename: filename, content_type: CONTENT_TYPE)
      import.update!(result_message: filename)
      import.complete_export!
    rescue => error
      import&.update!(result_message: "Exception: #{error.message}")
      import&.failure!
    end
  end
end
