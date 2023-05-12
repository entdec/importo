module Importo
  class Result < ApplicationRecord
    belongs_to :import, class_name: "Importo::Import"
  end
end
