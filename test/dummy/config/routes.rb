# frozen_string_literal: true

Rails.application.routes.draw do
  mount Importo::Engine => "/imports"
end
