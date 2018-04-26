# frozen_string_literal: true

module Importo
  class ImportColumn
    attr_accessor :name, :hint, :options, :proc

    def initialize(name, hint, options, &block)
      @name = name
      @hint = hint
      @options = options || {}
      @proc = block
    end
  end
end
