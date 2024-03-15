# frozen_string_literal: true

module Importo
  class ImportColumn
    attr_accessor :proc, :options
    attr_writer :name, :hint, :explanation, :value, :example

    def initialize(name: nil, **options, &block)
      @name = name
      @hint = options[:hint]
      @explanation = options[:explanation]
      @options = options || {}
      @proc = block
    end

    def attribute
      options[:attribute] || @name
    end

    def name
      name = options[:attribute] || @name
      I18n.t(".column.#{name}", scope: [:importers, options[:scope]], default: name)
    end

    def allowed_names
      return @allowed_names if @allowed_names.present?

      name = options[:attribute] || @name

      @allowed_names = I18n.available_locales.map do |locale|
        I18n.t(".column.#{name}", scope: [:importers, options[:scope]], locale: locale, default: name)
      end.compact.uniq
    end

    def hint
      I18n.t(".hint.#{options[:attribute]}", scope: [:importers, options[:scope]], default: "") if options[:attribute]
    end

    def explanation
      I18n.t(".explanation.#{options[:attribute]}", scope: [:importers, options[:scope]], default: "") if options[:attribute]
    end

    def value
      I18n.t(".value.#{options[:attribute]}", scope: [:importers, options[:scope]], default: "") if options[:attribute]
    end

    def example
      I18n.t(".example.#{options[:attribute]}", scope: [:importers, options[:scope]], default: "") if options[:attribute]
    end

    ##
    # If set this allows the user to set a value during upload that overrides the uploaded values.
    def overridable?
      options[:overridable]
    end

    ##
    # Collection of values (name, id) that are valid for this field, if a name is entered it will be replaced by the id during pre-processing
    def collection
      options[:collection]
    end

    def delay
      options[:delay]
    end
  end
end
