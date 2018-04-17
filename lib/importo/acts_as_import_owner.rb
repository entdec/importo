# frozen_string_literal: true

module Importo
  module ActsAsImportOwner
    extend ActiveSupport::Concern

    included do
      has_many :import, as: :importo_ownable, class_name: 'Importo::Import'
    end
  end
end
