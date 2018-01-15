# frozen_string_literal: true

class ImportsController < ApplicationController
  before_action :authenticate_user!
  authorize_resource

  add_breadcrumb I18n.t('breadcrumbs.admin.imports'), :admin_imports_path # view logic

  def new
    @import = Import.new(kind: params[:kind])
    @columns = @import.importable_fields
  end

  def create
    @import = Import.new(import_params.merge(user: current_user))
    if @import.valid? && @import.schedule!
      redirect_to admin_new_import_url, notice: t('.flash.success', id: @import.id)
    else
      @columns = @import.importable_fields
      flash[:error] = t('.flash.error')
      render :new
    end
  end

  def sample
    send_data Import.new(kind: params[:kind]).importer.sample_file.read, type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', filename: 'sample.xlsx'
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
