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
        alert_cell = style.add_style(bg_color: 'dd7777')
        duplicate_cell = style.add_style(bg_color: 'ddd777')

        sheet = workbook.add_worksheet(name: I18n.t('importo.sheet.results.name'))

        headers = (header_names - headers_added_by_import) + headers_added_by_import
        rich_text_headers = headers.map { |header| Axlsx::RichText.new.tap { |rt| rt.add_run(header.dup, b: true) } }
        sheet.add_row rich_text_headers
        loop_data_rows do |attributes, index|
          row_state = result(index, 'state')

          style = case row_state
                  when 'duplicate'
                    duplicate_cell
                  when 'failure'
                    alert_cell
                  end
          sheet.add_row attributes.values + results(index), style: Array.new(attributes.values.count) + Array.new(headers_added_by_import.count) { style }
        end

        sheet.auto_filter = "A1:#{sheet.dimension.last_cell_reference}"
      end

      xls.to_stream
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
