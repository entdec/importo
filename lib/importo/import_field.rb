# frozen_string_literal: true

module Importo
  class ImportField
    attr_accessor :name, :description, :options

    def initialize(name, description, options)
      @name = name
      @description = description
      @options = options
    end
  end
end
