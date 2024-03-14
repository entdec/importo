# frozen_string_literal: true

require "rails/generators/base"

module Importo
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates", __dir__)

      desc "Creates a Importo initializer and copy locale files to your application."

      def copy_initializer
        template "importo.rb", "config/initializers/importo.rb"
      end

      def copy_locale
        copy_file "../../../config/locales/en.yml", "config/locales/importo.en.yml"
        copy_file "../../../config/locales/nl.yml", "config/locales/importo.nl.yml"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end
