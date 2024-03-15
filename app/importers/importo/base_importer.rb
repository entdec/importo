# frozen_string_literal: true

module Importo
  class BaseImporter
    include ActiveSupport::Callbacks
    include ActionView::Helpers::SanitizeHelper
    include Importable
    include Exportable
    include Revertable
    include Original
    include ResultFeedback
    include ImporterDsl

    # include ActiveStorage::Downloading

    define_callbacks :row_import

    Importo::Import.state_machine.states.map(&:name).each do |state|
      define_callbacks state
    end

    delegate :friendly_name, :introduction, :model, :columns, :csv_options, :allow_duplicates?, :includes_header?,
      :ignore_header?, :t, to: :class
    attr_reader :import, :blob

    def initialize(imprt = nil)
      @import = imprt
      I18n.locale = import.locale if import&.locale # Should we do this?? here??
    end

    def state_changed(_import, transition)
      run_callbacks(transition.to_name) do
      end
    end

    class << self
      def t(key, options = {})
        if I18n.exists? :"importers.#{name.underscore}#{key}"
          I18n.t(key, options.merge(scope: :"importers.#{name.underscore}"))
        end
      end
    end
  end
end
