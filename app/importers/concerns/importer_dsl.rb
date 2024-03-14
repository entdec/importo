# frozen_string_literal: true

require "active_support/concern"

module ImporterDsl
  extend ActiveSupport::Concern

  included do
    delegate :allow_revert?, :overridable_columns, to: :class
  end

  class_methods do
    def friendly_name(friendly_name = nil)
      @friendly_name = friendly_name if friendly_name
      @friendly_name || model || name
    end

    def introduction(introduction = nil)
      @introduction ||= []
      @introduction = introduction if introduction
      @introduction
    end

    def columns
      @columns ||= {}
      @columns
    end

    #
    # Adds a column definition
    #
    # @param [Object] args
    # @param [Object] block which will filter the results before storing the value in the attribute, this is useful for lookups or reformatting
    def column(**options, &block)
      name ||= options[:name]
      name ||= options[:attribute]
      options[:scope] = name.to_s.underscore.to_s.tr("/", ".").to_sym
      columns[name] = Importo::ImportColumn.new(name: name, **options, &block)
    end

    def model(model = nil)
      @model = model if model
      @model
    end

    def allow_duplicates(duplicates)
      @allow_duplicates = duplicates if duplicates
      @allow_duplicates
    end

    def allow_revert(allow)
      @allow_revert = allow
    end

    def allow_export(allow)
      @allow_export = allow
    end

    def includes_header(includes_header)
      @includes_header = includes_header if includes_header
      @includes_header
    end

    def ignore_header(ignore_header)
      @ignore_header = ignore_header if ignore_header
      @ignore_header
    end

    def csv_options(csv_options = nil)
      @csv_options = csv_options if csv_options
      @csv_options
    end

    ##
    # Set to true to allow duplicate rows to be processed, if false (default) duplicate rows will be marked duplicate and ignored.
    #
    def allow_duplicates?
      @allow_duplicates
    end

    ##
    # Set to true when a header is/needs to be present in the file.
    #
    def includes_header?
      @includes_header
    end

    ##
    # Allow reverting the import
    # by default the successfully created records will be destroyed, override this behaviour with the undo method
    #
    def allow_revert?
      @allow_revert
    end

    ##
    # Allow exporting data
    #
    def allow_export?
      @allow_export
    end

    ##
    # Set to true when we need to ignore the header for structure check
    #
    def ignore_header?
      @ignore_header
    end

    def overridable_columns
      columns.select { |_name, column| column.overridable? }&.map(&:last)
    end
  end
end
