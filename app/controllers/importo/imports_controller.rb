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
      @import = Import.new(import_params.merge(locale: I18n.locale, importo_ownable: Importo.config.current_import_owner))
      if @import.valid? && @import.schedule!
        redirect_to new_import_url, notice: t('.flash.success', id: @import.id)
      else
        flash[:error] = t('.flash.error')
        render :new
      end
    end

    def sample
      send_data Import.new(kind: params[:kind], locale: I18n.locale).importer.sample_file.read, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: 'sample.xlsx'
    end

    def index
      @imports = Import.where(importo_ownable: Importo.config.current_import_owner).order(created_at: :desc).limit(50)
    end

    private

    def import_params
      return @import_params if @import_params
      tmp_file = params[:import][:file_name].path if params[:import][:file_name]
      uploaded_file = "#{Rails.root}/tmp/import/#{SecureRandom.hex}.#{tmp_file.split('.').last}"
      FileUtils.mkdir_p "#{Rails.root}/tmp/import"
      FileUtils.cp tmp_file, uploaded_file
      params[:import][:file_name] = uploaded_file
      @import_params = params.require(:import).permit(:file_name, :kind)
    end
  end
end
