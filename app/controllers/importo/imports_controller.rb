# frozen_string_literal: true

require_dependency 'importo/application_controller'

module Importo
  class ImportsController < ApplicationController
    add_breadcrumb I18n.t('importo.breadcrumbs.imports') if defined? add_breadcrumb

    def new
      @import = Import.new(kind: params[:kind], locale: I18n.locale)
      add_breadcrumb @import.importer.friendly_name if defined? add_breadcrumb
    end

    def create
      unless import_params
        @import = Import.new(kind: params[:kind], locale: I18n.locale)
        flash[:error] = t('.flash.no_file')
        render :new
        return
      end
      @import = Import.new(import_params.merge(locale: I18n.locale, importo_ownable: Importo.config.current_import_owner))
      if @import.valid? && @import.schedule!
        flash[:notice] = t('.flash.success', id: @import.id)
        redirect_to action: :index
      else
        flash[:error] = t('.flash.error')
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
      @import.destroy
      redirect_to action: :index
    end

    def sample
      send_data Import.new(kind: params[:kind], locale: I18n.locale).importer.sample_file.read, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: 'sample.xlsx'
    end

    def export
      send_data Import.new(kind: params[:kind], locale: I18n.locale).importer.export_file.read, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: 'export.xlsx'
    end

    def index
      @imports = Import.where(importo_ownable: Importo.config.current_import_owner).order(created_at: :desc).limit(50)
    end

    private

    def import_params
      params.require(:import).permit(:original, :kind)
    end
  end
end
