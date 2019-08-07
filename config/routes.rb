# frozen_string_literal: true

Importo::Engine.routes.draw do
  resources :imports, except: %i[new] do
    member do
      post :undo
    end
  end
  get ':kind/new', to: 'imports#new', as: :new_import
  get ':kind/sample', to: 'imports#sample', as: :sample_import
  root to: 'imports#index'
end
