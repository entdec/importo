class ImporterGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def copy_initializer_file
    template "application_importer.rb", "app/importers/application_importer.rb"
    template "importer.rb", "app/importers/#{file_name}_importer.rb"
  end
end
