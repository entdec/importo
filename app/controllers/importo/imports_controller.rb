# frozen_string_literal: true

require_dependency 'importo/application_controller'

module Importo
  class ImportsController < ApplicationController
    def new
      @import = Import.new(kind: params[:kind], locale: I18n.locale)
    end

    def create
      unless import_params
        @import = Import.new(kind: params[:kind], locale: I18n.locale)
        Signum.error(Current.user, text: t('.flash.no_file'))
        render :new
        return
      end
      @import = Import.new(import_params.merge(locale: I18n.locale,
                                               importo_ownable: Importo.config.current_import_owner))
      if @import.valid? && @import.schedule!
        redirect_to action: :index
      else
        Signum.error(Current.user, text: t('.flash.error', error: @import.errors&.full_messages&.join('.')))
        render :new
      end
    end

    def undo
      @import = Import.where(importo_ownable: Importo.config.current_import_owner).find(params[:id])
      if @import.can_revert? && @import.revert
        redirect_to action: :index, notice: 'Import reverted'
      else
        redirect_to action: :index, alert: 'Import could not be reverted'
      end
    end

    def destroy
      @import = Import.where(importo_ownable: Importo.config.current_import_owner).find(params[:id])
      redirect_to(action: :index, alert: 'Not allowed') && return unless Importo.config.admin_can_destroy(@import)

      @import.destroy
      redirect_to action: :index
    end

    def sample
      import = Import.new(kind: params[:kind], locale: I18n.locale)
      send_data import.importer.sample_file.read,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: import.importer.file_name('sample')
    end

    def export
      import = Import.new(kind: params[:kind], locale: I18n.locale)
      send_data import.importer.export_file.read,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: import.importer.file_name('export')
    end

    def index
      @imports = Importo.config.admin_visible_imports.order(created_at: :desc).limit(50)
    end

    private

    def import_params
      params.require(:import).permit(:original, :kind, :column_overrides,
                                     column_overrides: params.dig(:import, :column_overrides)&.keys)
    end
  end
end
