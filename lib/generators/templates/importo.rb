# frozen_string_literal: true

Importo.setup do |config|
  config.base_controller = '::ApplicationController'
  config.admin_authentication_module = 'Authenticated'

  # Current import owner
  config.current_import_owner = -> { User.current }

  # Set callbacks for the import states. You can configure callbacks to work with different states
  config.import_callbacks = {
      importing: lambda do |import|
      end,
      completed: lambda do |import|
      end,
      failed: lambda do |import|
      end
  }

  config.queue_name = :import
end
