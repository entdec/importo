# frozen_string_literal: true

module Importo
  class ApplicationController < Importo.config.base_controller.constantize
    include MaintenanceStandards
    include Importo.config.admin_authentication_module.constantize if Importo.config.admin_authentication_module
  end
end
