# frozen_string_literal: true

module Importo
  class BaseImporter
    include ActionView::Helpers::SanitizeHelper
    include Importable
    include Exportable
    include Revertable
    include Original
    include ResultFeedback
    include ImporterDSL
    include ActiveStorage::Downloading

    delegate :friendly_name, :introduction, :model, :columns, :csv_options, :allow_duplicates?, :includes_header?, :ignore_header?, :t, to: :class
    attr_reader :import, :blob

    def initialize(imprt = nil)
      @import = imprt
      I18n.locale = import.locale # Should we do this?? here??
    end

    class << self
      def t(key, options = {})
        I18n.t(key, options.merge(scope: "importers.#{name.underscore}".to_sym)) if I18n.exists? "importers.#{name.underscore}#{key}".to_sym
      end
    end
  end
end
