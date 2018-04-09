# frozen_string_literal: true

module Importo
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
