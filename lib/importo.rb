# frozen_string_literal: true

require 'axlsx'
require 'roo'
require 'roo-xls'
require 'slim'
require 'state_machines-activerecord'
require 'signum'
require 'turbo-rails'
require 'view_component'
# require 'active_storage/downloading'

require_relative 'importo/engine'
require_relative 'importo/acts_as_import_owner'
require_relative 'importo/import_column'
require_relative 'importo/import_helpers'
require_relative 'importo/configuration'

module Importo
  extend Configurable

  class Error < StandardError; end

  class DuplicateRowError < Error; end
end
