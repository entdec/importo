# frozen_string_literal: true

require "axlsx"
require "roo"
require "roo-xls"
require "slim"
require "state_machines-activerecord"
require "signum"
require "turbo-rails"
require "view_component"
require "with_advisory_lock"

module Importo
  class Engine < ::Rails::Engine
    isolate_namespace Importo
  end
end
