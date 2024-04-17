# frozen_string_literal: true

if defined? Mensa && defined? sts.mensa
  class Importo::MensaImportsTable < Mensa::Base
    definition do
      model Importo::Import

      column(:created_at)
      column(:user) do
        attribute "TRIM(CONCAT(users.first_name, ' ', users.last_name))"
      end
      column(:kind)
      column(:original) do
        sortable false
        render do
          html do |import|
            link_to(import.original.filename, main_app.rails_blob_path(import.original, disposition: "attachment"), target: "_blank")
          end
        end
      end

      column(:state)

      column(:result_message) do
        internal true
      end

      column(:result) do
        sortable false
        render do
          html do |import|
            if import.result.attached?
              link_to(import.result_message, main_app.rails_blob_path(import.result, disposition: "attachment"), target: "_blank")
            else
              import.result_message
            end
          end
        end
      end


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
