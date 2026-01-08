# frozen_string_literal: true

require_dependency "importo/application_controller"

module Importo
  class ImportsController < ApplicationController
    def new
      @import = Import.new(kind: params[:kind], locale: I18n.locale)
    end

    def preview
      @import = Import.find(params[:id])
      if @import&.original&.attachment.present?
        @original = Tempfile.new(["ActiveStorage", @import.original.filename.extension_with_delimiter])
        @original.binmode
        @import.original.download { |block| @original.write(block) }
        @original.flush
        @original.rewind
        sheet = Roo::Excelx.new(@original.path)
        @sheet_data = sheet.parse(headers: true)
        @check_header = @sheet_data.reject { |h| h.keys == h.values }.map { |h| h.transform_values(&:to_s).compact_blank }.reduce({}, :merge).keys
      end
      if @sheet_data.nil? || @sheet_data.reject { |h| h.keys == h.values }.blank?
        Signum.error(Current.user, text: t(".no_file"))
        redirect_to action: :new
      end
    end

    def create
      unless import_params["original"].present?
        @import = Import.new(kind: import_params[:kind], locale: I18n.locale)
        Signum.error(Current.user, text: t(".flash.no_file"))
        render :new
        return
      end
      @import = Import.new(import_params.merge(locale: I18n.locale,
        importo_ownable: Importo.config.current_import_owner.call))
      if params["commit"] == "Upload" && @import.valid? && @import.save!
        @import.confirm!
        @import.schedule!
        redirect_to importo.new_import_path(params[:kind] || @import.kind)
      elsif params["commit"] == "Preview" && @import.valid?
        @import.save!
        redirect_to action: :preview, id: @import.id, kind: @import.kind
      else
        Signum.error(Current.user, text: t(".flash.error", error: @import.errors&.full_messages&.join(".")))
        render :new
      end
    end

    def cancel
      @import = Import.find(params[:id])
      @import.original.purge if @import.concept?
      Signum.error(Current.user, text: t(".flash.cancel", id: @import.id))
      @import.destroy!
      redirect_to action: :new, kind: @import.kind
    end

    def undo
      @import = Import.where(importo_ownable: Importo.config.current_import_owner.call).find(params[:id])
      if @import.can_revert? && @import.revert
        redirect_to action: :index, notice: "Import reverted"
      else
        redirect_to action: :index, alert: "Import could not be reverted"
      end
    end

    def upload
      @import = Import.find(params[:id])
      @import.checked_columns = params[:selected_items]&.reject { |element| element == "0" }
      @import.confirm! if @import.can_confirm?
      if @import.valid? && @import.schedule!
        redirect_to action: :index
      else
        Signum.error(Current.user, text: t(".flash.error", id: @import.id))
        render :new
      end
    end

    def destroy
      @import = Import.find(params[:id])
      redirect_to(action: :index, alert: "Not allowed") && return unless Importo.config.admin_can_destroy.call(@import)

      @import.destroy
      redirect_to action: :index
    end

    def sample
      import = Import.new(kind: params[:kind], locale: I18n.locale)
      send_data import.importer.sample_file.read,
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: import.importer.file_name("sample")
    end

    def export
      import = Import.new(kind: params[:kind], locale: I18n.locale)
      send_data import.importer.export_file.read,
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", filename: import.importer.file_name("export")
    end

    def index
      @imports = Importo.config.admin_visible_imports.call.order(created_at: :desc).limit(50)
    end

    private

    def import_params
      params.require(:import).permit(:original, :kind, :column_overrides,
        column_overrides: params.dig(:import, :column_overrides)&.keys)
    end
  end
end
