# frozen_string_literal: true

module Importo
  class BaseImporter
    include ActionView::Helpers::SanitizeHelper

    delegate :friendly_name, :fields, :csv_options, :allow_duplicates?, :includes_header?, :ignore_header?, to: :class
    attr_reader :import

    def initialize(imprt = nil)
      @import = imprt
    end

    def build
      raise NotImplementedError, "Implement 'build' method in #{self.class.name} class"
    end

    def before_save(record, row)
      # Implement optionally in child class to mangle
    end

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

    def structure_valid?
      return true if !includes_header? || ignore_header?
      invalid_header_names.count.zero?
    end

    def header_names
      return fields.keys if !includes_header? || ignore_header?
      @header_names ||= cells_from_row(header_row)
    end

    def invalid_header_names
      invalid_header_names_for_row(1)
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

    def sample_file
      xls = Axlsx::Package.new
      workbook = xls.workbook
      sheet = workbook.add_worksheet(name: 'Import')
      sheet.add_row fields.keys

      fields.each.with_index do |f, i|
        sheet.add_comment ref: "#{('A'..'Z').to_a[i]}1", author: self.class.name, text: f.last, visible: false if f.last.present?
      end

      xls.to_stream
    end

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

    private

    def process_data_row(attributes, index)
      record = nil

      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          row_hash = Digest::SHA256.base64digest(attributes.inspect)
          register_result(index, hash: row_hash, state: :processing)
          next if duplicate?(index, row_hash)

          record = build(attributes)
          record.validate!
          before_save(record, attributes)
          record.save!
          register_result(index, class: record.class.name, id: record.id, state: :success)
        end
        record
      rescue StandardError => e
        errors = record.respond_to?(:errors) && record.errors.full_messages.join(', ')
        register_result(index, class: record.class.name, state: :failure, message: e.message, errors: errors)
        nil
      end
    end

    def duplicate?(index, row_hash)
      return false if allow_duplicates?

      duplicate = Import.where("results @> '[{\"hash\": \"#{row_hash}\", \"state\": \"success\"}]'").first
      return false unless duplicate

      record_id = duplicate.results.find { |data| data['hash'] == row_hash }['id']
      register_result(index, id: record_id, state: :duplicate, message: "Row already imported successfully on #{duplicate.created_at.to_date}")
      true
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

      # TODO: Implement search lines 1 through 10 for best matching header with `invalid_header_names_for_row(index)`
      @header_row ||= 1
    end

    def invalid_header_names_for_row(index)
      cells_from_row(index).map { |header| allowed_header_names.include?(header) ? nil : header }.compact
    end

    def allowed_header_names
      @allowed_header_names ||= fields.keys + headers_added_by_import
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

    class << self

      def friendly_name(friendly_name = nil)
        @friendly_name = friendly_name if friendly_name
        @friendly_name || name
      end

      def fields(data = nil)
        @fields = data if data
        @fields
      end

      def allow_duplicates(duplicates)
        @allow_duplicates = duplicates if duplicates
        @allow_duplicates
      end

      def includes_header(includes_header)
        @includes_header = includes_header if includes_header
        @includes_header
      end

      def ignore_header(ignore_header)
        @ignore_header = ignore_header if ignore_header
        @ignore_header
      end

      def csv_options(csv_options = nil)
        @csv_options = csv_options if csv_options
        @csv_options
      end

      ##
      # Set to true to allow duplicate rows to be processed, if false (default) duplicate rows will be marked duplicate and ignored.
      #
      def allow_duplicates?
        @allow_duplicates
      end

      ##
      # Set to true when a header is/needs to be present in the file.
      #
      def includes_header?
        @includes_header
      end

      ##
      # Set to true when we need to ignore the header for structure check
      #
      def ignore_header?
        @ignore_header
      end
    end
  end
end
