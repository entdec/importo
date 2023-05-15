Importo.setup do |config|
  config.current_import_owner = -> { Current.user }
end