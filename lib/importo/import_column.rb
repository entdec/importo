# frozen_string_literal: true

module Importo
  class ImportColumn
    attr_accessor :name, :description, :options, :proc

    def initialize(name, description, options, &block)
      @name = name
      @description = description
      @options = options || {}
      @proc = block
    end
  end
end
