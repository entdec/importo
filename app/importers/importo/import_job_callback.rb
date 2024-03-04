module Importo
  class ImportJobCallback
    include Rails.application.routes.url_helpers

    def on_complete(_status, options)
      options = options.deep_stringify_keys
      import = Import.find(options['import_id'])
      if import.present? && _status.pending.zero?
        import.result.attach(io: import.importer.results_file, filename: import.importer.file_name('results'),
                             content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

        import.result_message = I18n.t('importo.importers.result_message',
                                       nr: import.results.where('details @> ?', { state: 'success' }.to_json).count, of: import.importer.send(:row_count))
        import.complete! if import.can_complete?
      end
    end

    def on_success(status, options)
      # puts "#{options['uid']}'s batch succeeded.  Kudos!"
      on_complete(status, options)
    end
  end
end
