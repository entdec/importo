# frozen_string_literal: true

module Importo
  class BaseImporter
    include ActionView::Helpers::SanitizeHelper
    include ImporterDSL

    delegate :friendly_name, :columns, :csv_options, :allow_duplicates?, :includes_header?, :ignore_header?, to: :class
    attr_reader :import

    def initialize(imprt = nil)
      @import = imprt
    end

    #
    # Build a record based on the row
    #
    def build(_row)
      raise NotImplementedError, "Implement 'build' method in #{self.class.name} class"
    end

    #
    # Mangle the record before saving
    #
    def before_save(_record, _row)
      # Implement optionally in child class to mangle
    end

    #
    # Does the actual import
    #
    def import!
      raise ArgumentError, 'Invalid data structure' unless structure_valid?

      results = loop_data_rows do |attributes, index|
        process_data_row(attributes, index)
      end
      @import.result_message = "Imported #{results.compact.count} of #{results.count} rows, starting from row #{data_start_row}"
      @import.complete!
    rescue StandardError => e
      @import.result_message = "Exception: #{e.message}"
      @import.failure!
    end

    #
    # Generates a sample excel file as a stream
    #
    def sample_file
      xls = Axlsx::Package.new
      workbook = xls.workbook
      sheet = workbook.add_worksheet(name: 'Import')
      sheet.add_row columns.keys

      columns.each.with_index do |f, i|
        field = f.last
        sheet.add_comment ref: "#{('A'..'ZZ').to_a[i]}1", author: self.class.name, text: field.description, visible: false if field.description.present?
      end

      xls.to_stream
    end

    #
    # Generates a result excel file as a stream
    #
    def results_file
      xls = Axlsx::Package.new
      workbook = xls.workbook
      workbook.styles do |style|
        alert_cell = style.add_style(bg_color: 'dd7777')
        duplicate_cell = style.add_style(bg_color: 'ddd777')

        sheet = workbook.add_worksheet(name: 'Import')

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

      FileUtils.rm @import.file_name

      xls.to_stream
    end

    def structure_valid?
      return true if !includes_header? || ignore_header?
      invalid_header_names.count.zero?
    end

    def invalid_header_names
      invalid_header_names_for_row(header_row)
    end

    private

    def header_names
      return columns.keys if !includes_header? || ignore_header?
      @header_names ||= cells_from_row(header_row)
    end

    def loop_data_rows
      (data_start_row..spreadsheet.last_row).map do |index|
        row = cells_from_row(index)
        attributes = Hash[[header_names, row].transpose]
        attributes.reject! { |k, _v| headers_added_by_import.include?(k) }

        yield attributes, index
      end
    end

    def row_count
      (spreadsheet.last_row - data_start_row) + 1
    end

    def headers_added_by_import
      %w[import_state import_created_id import_message import_errors].map(&:dup)
    end

    def process_data_row(attributes, index)
      record = nil
      row_hash = Digest::SHA256.base64digest(attributes.inspect)

      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          register_result(index, hash: row_hash, state: :processing)

          record = build(attributes)
          record.validate!
          before_save(record, attributes)
          record.save!
          raise Importo::DuplicateRowError if duplicate?(row_hash, record.id)
          register_result(index, class: record.class.name, id: record.id, state: :success)
        end
        record
      rescue Importo::DuplicateRowError
        dpl = duplicate(row_hash, record.id)
        record_id = dpl.results.find { |data| data['hash'] == row_hash }['id']
        register_result(index, id: record_id, state: :duplicate, message: "Row already imported successfully on #{dpl.created_at.to_date}")
        nil
      rescue StandardError => e
        errors = record.respond_to?(:errors) && record.errors.full_messages.join(', ')
        register_result(index, class: record.class.name, state: :failure, message: e.message, errors: errors)
        nil
      end
    end

    def duplicate(row_hash, id)
      Import.where("results @> '[{\"hash\": \"#{row_hash}\", \"state\": \"success\"}]' AND id <> :id", id: id).first
    end

    def duplicate?(row_hash, id)
      return false if allow_duplicates?
      duplicate(row_hash, id)
    end

    def cells_from_row(index)
      spreadsheet.row(index).map { |c| cleaned_data_from_cell(c) }
    end

    def cleaned_data_from_cell(cell)
      if cell.respond_to?(:strip)
        strip_tags cell.strip
      else
        cell
      end
    end

    def data_start_row
      header_row + 1
    end

    def header_row
      return 0 unless includes_header?
      return @header_row if @header_row

      most_valid_counts = (1..10).map do |row_nr|
        [row_nr, cells_from_row(row_nr).reject(&:nil?).size - invalid_header_names_for_row(row_nr).size]
      end
      @header_row = most_valid_counts.max { |a, b| a.last <=> b.last }.first
    end

    def invalid_header_names_for_row(index)
      cells_from_row(index).map { |header| allowed_header_names.include?(header) ? nil : header }.compact
    end

    def allowed_header_names
      @allowed_header_names ||= columns.keys + headers_added_by_import
    end

    def spreadsheet
      @spreadsheet ||= case File.extname(@import.file_name)
                       when '.csv' then Roo::CSV.new(@import.file_name, csv_options: csv_options)
                       when '.xls' then Roo::Excel.new(@import.file_name)
                       when '.xlsx' then Roo::Excelx.new(@import.file_name)
                       else raise "Unknown file type: #{@import.file_name.split('/').last}"
                       end
    end

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
      [result(index, 'state'), result(index, 'id'), result(index, 'message'), result(index, 'errors')]
    end

    def result(index, field)
      (@import.results.find { |result| result['row'] == index } || {}).fetch(field, nil)
    end
  end
end
