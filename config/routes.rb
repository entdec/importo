# frozen_string_literal: true

Importo::Engine.routes.draw do
  resources :imports, except: %i[new] do
    member do
      post :undo
      post :upload
      post :cancel
    end
  end
  get ':kind/new', to: 'imports#new', as: :new_import
  get ':kind/sample', to: 'imports#sample', as: :sample_import
  get ':kind/export', to: 'imports#export', as: :export
  get ':kind/:id/preview', to: 'imports#preview', as: :preview
  root to: 'imports#index'
end
