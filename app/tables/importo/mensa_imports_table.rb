# frozen_string_literal: true

if defined? Mensa
  class Importo::MensaImportsTable < Mensa::Base
    definition do
      model Importo::Import

      column(:created_at)
      column(:user)
      column(:kind)
      column(:original)
      column(:state)
      column(:result)

      order created_at: :desc
    end

    private

    def scope
      @scope = Importo.config.admin_visible_imports.call
      @scope = @scope.joins("LEFT JOIN users on importo_imports.importo_ownable_type = 'User' and importo_imports.importo_ownable_id = users.id ")
    end

    def filtered_scope
      @filtered_scope = scope
      @filtered_scope = @filtered_scope.where(importo_ownable_type: params[:ownable].split("#").first, importo_ownable_id: params[:ownable].split("#").last) if params[:ownable]
      @filtered_scope = @filtered_scope.where(kind: params[:kind]) if params[:kind]
      @filtered_scope
    end
  end
else
  class Importo::MensaImportsTable
  end
end
