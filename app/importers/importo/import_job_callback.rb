module Importo
  class ImportJobCallback
    include Rails.application.routes.url_helpers
    
    def on_complete(status, options)
      import = Import.find(options["import_id"])
      if import.present?
        import.result.attach(io: import.importer.results_file, filename: import.importer.file_name('results'), 
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        
        import.result_message = I18n.t('importo.importers.result_message', nr: import.results.where('details @> ?', {state: "success"}.to_json).count, of: import.importer.send(:row_count))
        
        import.complete!

        if import.result.attached?
          signal = Signum::Signal.find(options["signal_id"])
          signal.update(metadata: {links: [{title: "Download", url: rails_blob_path(import.result, disposition: "attachment", only_path: true)}]})
        end
      end
    end
    
    def on_success(status, options)
      #puts "#{options['uid']}'s batch succeeded.  Kudos!"
    end
  end
end