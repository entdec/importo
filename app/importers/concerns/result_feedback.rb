# frozen_string_literal: true

require "active_support/concern"

module ResultFeedback
  extend ActiveSupport::Concern

  #
  # Generates a result excel file as a stream
  #
  def results_file
    xls = Axlsx::Package.new
    xls.use_shared_strings = true
    workbook = xls.workbook
    workbook.styles do |style|
      alert_cell_bg_color = "dd7777"
      duplicate_cell_bg_color = "ddd777"

      sheet = workbook.add_worksheet(name: I18n.t("importo.sheet.results.name"))
      headers = (header_names - headers_added_by_import) + headers_added_by_import
      headers_style = headers.map do |header|
        workbook.styles.add_style(bg_color: "619657")
      end
      rich_text_headers = headers.map { |header| Axlsx::RichText.new.tap { |rt| rt.add_run(header.dup, b: true) } }
      sheet.add_row rich_text_headers, style: headers_style
      loop_data_rows do |attributes, index|
        row_state = result(index, :state)
        bg_color = case row_state.to_s
        when "duplicate"
          duplicate_cell_bg_color
        when "failure"
          alert_cell_bg_color
        end
        styles = []
        attributes.map do |column, value|
          export_format = columns[column]&.options&.dig(:export, :format)
          format_code = if export_format == "number" || (export_format.nil? && value.is_a?(Numeric))
            "#"
          elsif export_format == "text" || (export_format.nil? && value.is_a?(String))
            "@"
          elsif export_format
            export_format.to_s
          else
            "General"
          end
          config_style = {}
          config_style.merge!(columns[column]&.options&.[](:style)) unless columns[column]&.options&.[](:style).nil?
          config_style.merge!({format_code: format_code, bg_color: bg_color})
          styles << workbook.styles.add_style(config_style)
        end
        header_array = []
        headers_added_by_import.count.times do |i|
          header_array << workbook.styles.add_style(bg_color: bg_color)
        end
        styles += header_array
        sheet.add_row attributes.values + results(index), style: styles
      end

      sheet.auto_filter = "A1:#{sheet.dimension.last_cell_reference}"
    end

    xls.to_stream
  end

  def file_name(suffix = nil)
    base = friendly_name || model.class.name
    base = base.to_s unless base.is_a?(String)
    base = base.gsub(/[_\s-]/, "_").pluralize.downcase
    "#{base}#{suffix.present? ? "_#{suffix}" : ""}.xlsx"
  end

  private

  def register_result(index, details)
    r = @import.results.find_or_create_by(row_index: index)
    r.details = details
    r.save
  end

  def results(index)
    [result(index, :state), result(index, :id), result(index, :message), result(index, :errors)]
  end

  def result(index, field)
    (@import.results.find_by(row_index: index)&.details || {}).fetch(field.to_s, nil)
  end
end
