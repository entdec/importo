# frozen_string_literal: true

Importo::Engine.routes.draw do
  get 'imports', to: 'imports#index', as: :imports_index
  get 'imports/:kind/new', to: 'imports#new', as: :new_import
  get 'imports/:kind/sample', to: 'imports#sample', as: :sample_import
  post 'imports/:kind/create', to: 'imports#create', as: :imports
end
