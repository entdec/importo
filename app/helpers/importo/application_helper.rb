# frozen_string_literal: true

module Importo
  module ApplicationHelper
    def respond_to_missing?(method)
      method.ends_with?('_url') || method.ends_with?('_path')
    end

    def method_missing(method, *args, &block)
      if main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end
  end
end
