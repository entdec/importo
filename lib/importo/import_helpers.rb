# frozen_string_literal: true

module Importo::ImportHelpers
  extend ActiveSupport::Concern

  included do
    has_one_attached :original
    has_one_attached :result
  end
end
