# frozen_string_literal: true

module Importo
  class BaseImporter
    include ActionView::Helpers::SanitizeHelper
    include ImporterDSL
    include ActiveStorage::Downloading

    delegate :friendly_name, :introduction, :model, :columns, :csv_options, :allow_duplicates?, :includes_header?, :ignore_header?, :t, to: :class
    attr_reader :import, :blob

    def initialize(imprt = nil)
      @import = imprt
      return unless import
      I18n.locale = import.locale

      return unless import.original.attached?
      @blob = import.original
      @original = Tempfile.new(['ActiveStorage', import.original.filename.extension_with_delimiter])
      @original.binmode
      download_blob_to @original
      @original.flush
      @original.rewind
    end

    #
    # Build a record based on the row, when you override build, depending on your needs you will need to
    # call populate yourself, or skip this altogether.
    #
    def build(row)
      populate(row)
    end

    def failure(row, record, index, exception)
      Rails.logger.error "#{exception.message} processing row #{index}: #{exception.backtrace.join(';')}"
    end

    #
    # Assists in pre-populating the record for you
    # It wil try and find the record by id, or initialize a new record with it's attributes set based on the mapping from columns
    #
    def populate(row, record = nil)
      raise 'No attributes set for columns' unless columns.any? { |_, v| v.options[:attribute].present? }

      result = if record
                 record
               else
                 raise 'No model set' unless model
                 model.find_or_initialize_by(id: row['id'])
               end

      cols_to_populate = columns.select do |_, v|
        v.options[:attribute].present?
      end

      cols_to_populate.each do |k, col|
        attributes = {}
        attr = col.options[:attribute]

        value = row[k]
        if value.present? && col.proc
          proc = col.proc
          proc_result = instance_exec value, record, row, &proc
          value = proc_result if proc_result
        end
        value || col.options[:default]

        attributes = set_attribute(attributes, attr, value) if value.present?

        # We assign each iteration to use intermediate results
        result.assign_attributes(attributes)
      end

      result
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
      @import.result.attach(io: results_file, filename: 'results.xlsx', content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')

      @import.result_message = "Imported #{results.compact.count} of #{results.count} rows, starting from row #{data_start_row}"
      @import.complete!
    rescue StandardError => e
      @import.result_message = "Exception: #{e.message}"
      Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(';')}"
      @import.failure!
    end

    #
    # Generates a sample excel file as a stream
    #
    def sample_file
      xls = Axlsx::Package.new
      xls.use_shared_strings = true
      workbook = xls.workbook
      sheet = workbook.add_worksheet(name: model.name.pluralize)
      workbook.styles do |style|
        introduction_style = style.add_style(bg_color: 'E2EEDA')
        header_style = style.add_style(b: true, bg_color: 'A8D08E', border: { style: :thin, color: '000000' })
        header_required_style = style.add_style(b: true, bg_color: 'A8D08E', fg_color: 'C00100', border: { style: :thin, color: '000000' })

        # Introduction
        introduction.each_with_index do |intro, i|
          text = intro.is_a?(Symbol) ? I18n.t(intro, scope: [:importers, self.class.name.underscore.to_s, :introduction]) : intro
          sheet.add_row [text], style: [introduction_style] * columns.count
          sheet.merge_cells "A#{i + 1}:#{nr_to_col(columns.count - 1)}#{i + 1}"
        end
        # binding.pry
        # Header row
        sheet.add_row columns.values.map(&:name), style: columns.map { |_, c| c.options[:required] ? header_required_style : header_style }

        columns.each.with_index do |f, i|
          field = f.last
          sheet.add_comment ref: "#{nr_to_col(i)}#{introduction.count + 1}", author: '', text: field.hint, visible: false if field.hint.present?
        end

        number = workbook.styles.add_style format_code: '#'
        text = workbook.styles.add_style format_code: '@'

        data = columns.map { |_, c| c.options[:example] ? c.options[:example] : '' }
        styles = columns.map { |_, c| c.options[:example].is_a?(Numeric) ? number : text }

        # Examples
        sheet.add_row data, style: styles
      end

      sheet.column_info[0].width = 10

      sheet = workbook.add_worksheet(name: I18n.t('importo.sheet.explanation.name'))

      workbook.styles do |style|
        introduction_style = style.add_style(bg_color: 'E2EEDA')
        header_style = style.add_style(b: true, bg_color: 'A8D08E', border: { style: :thin, color: '000000' })

        column_style = style.add_style(b: true)
        required_style = style.add_style(b: true, fg_color: 'C00100')
        wrap_style = workbook.styles.add_style alignment: { wrap_text: true }

        # Introduction
        introduction.each_with_index do |intro, i|
          text = intro.is_a?(Symbol) ? I18n.t(intro, scope: [:importers, self.class.name.underscore.to_s, :introduction]) : intro
          sheet.add_row [text], style: [introduction_style] * 2
          sheet.merge_cells "A#{i + 1}:B#{i + 1}"
        end

        # Header row
        sheet.add_row [I18n.t('importo.sheet.explanation.column'), I18n.t('importo.sheet.explanation.explanation')], style: [header_style] * 2
        columns.each do |_, c|
          styles = [c.options[:required] ? required_style : column_style, wrap_style]
          sheet.add_row [c.name, c.explanation], style: styles
        end
      end

      sheet.column_info[0].width = 40
      sheet.column_info[1].width = 150

      xls.to_stream
    end

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

    def structure_valid?
      return true if !includes_header? || ignore_header?
      invalid_header_names.count.zero?
    end

    def invalid_header_names
      invalid_header_names_for_row(header_row)
    end

    def col_for(translated_name)
      col = columns.detect do |k, v|
        v.name == translated_name || k == translated_name
      end
      col
    end

    private

    class << self
      def t(key, options = {})
        I18n.t(key, options.merge(scope: "importers.#{name.underscore}".to_sym)) if I18n.exists? "importers.#{name.underscore}#{key}".to_sym
      end
    end

    def nr_to_col(number)
      ('A'..'ZZ').to_a[number]
    end

    def set_attribute(hash, path, value)
      tmp_hash = path.split('.').reverse.inject(value) { |h, s| { s => h } }
      hash.deep_merge(tmp_hash)
    end

    def attribute_names
      return columns.keys if !includes_header? || ignore_header?
      translated_header_names = cells_from_row(header_row)
      @header_names = translated_header_names.map do |name|
        col_for(name).first
      end
    end

    def header_names
      return columns.values.map(&:name) if !includes_header? || ignore_header?
      @header_names ||= cells_from_row(header_row)
    end

    def loop_data_rows
      (data_start_row..spreadsheet.last_row).map do |index|
        row = cells_from_row(index)
        attributes = Hash[[attribute_names, row].transpose]
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
      duplicate_import = nil

      begin
        ActiveRecord::Base.transaction(requires_new: true) do
          register_result(index, hash: row_hash, state: :processing)

          record = build(attributes)
          record.validate!
          before_save(record, attributes)
          record.save!
          duplicate_import = duplicate?(row_hash, record.id)
          raise Importo::DuplicateRowError if duplicate_import
          register_result(index, class: record.class.name, id: record.id, state: :success)
        end
        record
      rescue Importo::DuplicateRowError
        record_id = duplicate_import.results.find { |data| data['hash'] == row_hash }['id']
        register_result(index, id: record_id, state: :duplicate, message: "Row already imported successfully on #{duplicate_import.created_at.to_date}")
        nil
      rescue StandardError => e
        errors = record.respond_to?(:errors) && record.errors.full_messages.join(', ')
        error_message = "#{e.message} (#{e.backtrace.first.split('/').last})"
        failure(attributes, record, index, e)
        register_result(index, class: record.class.name, state: :failure, message: error_message, errors: errors)
        nil
      end
    end

    def duplicate(row_hash, id)
      Import.where("results @> '[{\"hash\": \"#{row_hash}\", \"state\": \"success\"}]' AND id <> :id", id: id).first
    end

    def duplicate?(row_hash, id)
      return false if allow_duplicates? || row_hash['id'] == id
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

      most_valid_counts = (1..20).map do |row_nr|
        [row_nr, cells_from_row(row_nr).reject(&:nil?).size - invalid_header_names_for_row(row_nr).size]
      end
      @header_row = most_valid_counts.max_by(&:last).first
    end

    def invalid_header_names_for_row(index)
      cells_from_row(index).map { |header| allowed_header_names.include?(header) ? nil : header }.compact
    end

    def allowed_header_names
      @allowed_header_names ||= columns.values.map(&:name) + headers_added_by_import
    end

    def spreadsheet
      @spreadsheet ||= case File.extname(@original.path)
                       when '.csv' then
                         Roo::CSV.new(@original.path, csv_options: csv_options)
                       when '.xls' then
                         Roo::Excel.new(@original.path)
                       when '.xlsx' then
                         Roo::Excelx.new(@original.path)
                       else
                         raise "Unknown file type: #{@original.path.split('/').last}"
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
