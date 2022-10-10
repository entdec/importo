# frozen_string_literal: true

require 'active_support/concern'

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
        alert_cell_bg_color = 'dd7777'
        duplicate_cell_bg_color = 'ddd777'

        sheet = workbook.add_worksheet(name: I18n.t('importo.sheet.results.name'))

        headers = (header_names - headers_added_by_import) + headers_added_by_import
        rich_text_headers = headers.map { |header| Axlsx::RichText.new.tap { |rt| rt.add_run(header.dup, b: true) } }
        sheet.add_row rich_text_headers
        loop_data_rows do |attributes, index|
          row_state = result(index, 'state')
          bg_color = case row_state
                  when 'duplicate'
                    duplicate_cell_bg_color
                  when 'failure'
                    alert_cell_bg_color
                  end
          styles = attributes.map do |column, value|
            export_format = columns[column]&.options.dig(:export, :format)
            if export_format == "number" || ( export_format.nil? && value.is_a?(Numeric)) 
              number = workbook.styles.add_style(format_code: '#', bg_color: bg_color)
            elsif export_format == 'text' || ( export_format.nil? && value.is_a?(String))
              text = workbook.styles.add_style(format_code: '@' , bg_color: bg_color)
            elsif export_format
              workbook.styles.add_style(format_code: export_format.to_s, bg_color: bg_color)
            else
              workbook.styles.add_style(format_code: 'General' , bg_color: bg_color)
            end
          end  
          
          styles = styles + Array.new(headers_added_by_import.count)
          sheet.add_row attributes.values + results(index), style: styles
        end

        sheet.auto_filter = "A1:#{sheet.dimension.last_cell_reference}"
      end

      xls.to_stream
    end

    def file_name(suffix = nil)
      base = friendly_name || model.class.name
      base = base.to_s unless base.is_a?(String)
      base = base.gsub(/[_\s-]/, '_').pluralize.downcase
      "#{base}#{suffix.present? ? "_#{suffix}" : '' }.xlsx"
    end

  private

  def register_result(index, details)
    @import.results ||= []
    i = @import.results.index { |data| data[:row] == index }
    if i
      @import.results[i].merge!(details)
    else
      @import.results << details.merge(row: index)
    end
  end

  def results(index)
    [result(index, :state), result(index, :id), result(index, :message), result(index, :errors)]
  end

  def result(index, field)
    (@import.results.find { |result| result[:row] == index } || {}).fetch(field, nil)
  end
end
