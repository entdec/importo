require 'active_support/concern'

module ImporterDSL
  extend ActiveSupport::Concern

  included do
  end

  class_methods do
    def friendly_name(friendly_name = nil)
      @friendly_name = friendly_name if friendly_name
      @friendly_name || name
    end

    def columns
      @columns ||= {}
      @columns
    end

    def column(name, description, options = {})
      columns[name] = Importo::ImportColumn.new(name, description, options)
    end

    def model(model)
      @model = model if model
      @model
    end

    def allow_duplicates(duplicates)
      @allow_duplicates = duplicates if duplicates
      @allow_duplicates
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
    # Set to true when we need to ignore the header for structure check
    #
    def ignore_header?
      @ignore_header
    end
  end
end
