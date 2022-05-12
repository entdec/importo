# frozen_string_literal: true

module Importo::ImportHelpers
  extend ActiveSupport::Concern

  included do
    has_one_attached :original, service: :importo
    has_one_attached :result, service: :importo
  end
end
