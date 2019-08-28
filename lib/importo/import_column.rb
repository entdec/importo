# frozen_string_literal: true

module Importo
  class ImportColumn
    attr_accessor :proc, :options
    attr_writer :name, :hint, :explanation

    def initialize(name, hint, explanation, options, &block)
      @name = name
      @hint = hint
      @explanation = explanation
      @options = options || {}
      @proc = block
    end

    def attribute
      options[:attribute] || @name
    end

    def name
      if options[:attribute]
        I18n.t(".column.#{options[:attribute]}", scope: [:importers, options[:scope]], default: options[:attribute])
      else
        I18n.t(".column.#{@name}", scope: [:importers, options[:scope]], default: @name)
      end
    end

    def hint
      I18n.t(".hint.#{options[:attribute]}", scope: [:importers, options[:scope]], default: '') if options[:attribute]
    end

    def explanation
      I18n.t(".explanation.#{options[:attribute]}", scope: [:importers, options[:scope]], default: '') if options[:attribute]
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
  end
end
