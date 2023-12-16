# frozen_string_literal: true

Importo.setup do |config|
  config.base_controller = '::ApplicationController'
  config.admin_authentication_module = 'Authenticated'

  # Current import owner
  config.current_import_owner = -> { User.current }

  config.queue_name = :import
end
