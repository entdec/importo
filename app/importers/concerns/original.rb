
# frozen_string_literal: true

require 'active_support/concern'

module Original
  extend ActiveSupport::Concern

  def original
    return @original if @original && !@original.is_a?(Hash)

    if import.respond_to?(:attachment_changes) && import.attachment_changes['original']
      @original ||= import.attachment_changes['original']&.attachable

      if @original.is_a?(Hash)
        tempfile = Tempfile.new(['ActiveStorage', import.original.filename.extension_with_delimiter])
        tempfile.binmode
        tempfile.write(@original[:io].read)
        @original[:io].rewind
        tempfile.rewind
        @original = tempfile
      end
    else
      return unless import&.original&.attachment

      @original = Tempfile.new(['ActiveStorage', import.original.filename.extension_with_delimiter])
      @original.binmode
      import.original.download { |block| @original.write(block) }
      @original.flush
      @original.rewind
    end

    @original
  end

  def structure_valid?
    return true if !includes_header? || ignore_header?

    invalid_header_names.count.zero?
  end

  def invalid_header_names
    invalid_header_names_for_row(header_row)
  end

  def col_for(translated_name)
    col = columns.detect { |k, v| v.name == translated_name || k == translated_name }
    col ||= columns.detect { |k, v| v.allowed_names.include?(translated_name) }
    col
  end

  private

  def headers_added_by_import
    %w[import_state import_created_id import_message import_errors].map(&:dup)
  end

  def cells_from_row(index, clean = true)
    spreadsheet.row(index).map { |c| clean ? cleaned_data_from_cell(c) : c }
  end

  def cleaned_data_from_cell(cell)
    return cell unless cell.respond_to?(:strip)

    strip_tags cell.strip
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
    stripped_headers = allowed_header_names.map { |name| name.to_s.gsub(/[^A-Za-z]/, '').downcase }
    cells_from_row(index).reject { |header| stripped_headers.include?(header.to_s.gsub(/[^A-Za-z]/, '').downcase) }
  end

  def allowed_header_names
    @allowed_header_names ||= columns.values.map(&:allowed_names).flatten + headers_added_by_import
  end

  def spreadsheet
    @spreadsheet ||= case File.extname(original.path)
                     when '.csv' then
                       Roo::CSV.new(original.path, csv_options: csv_options)
                     when '.xls' then
                       Roo::Excel.new(original.path)
                     when '.xlsx' then
                       Roo::Excelx.new(original.path)
                     else
                       raise "Unknown file type: #{original.path.split('/').last}"
                     end
  end

  def duplicate(row_hash, id)
    Importo::Import.where("results @> '[{\"hash\": \"#{row_hash}\", \"state\": \"success\"}]' AND id <> :id", id: id).first
  end

  def duplicate?(row_hash, id)
    return false if allow_duplicates? || row_hash['id'] == id

    duplicate(row_hash, id)
  end

  def loop_data_rows
    (data_start_row..spreadsheet.last_row).map do |index|
      row = cells_from_row(index, false)
      attributes = Hash[[attribute_names, row].transpose]
      attributes = attributes.map do |column, value|
        value = strip_tags(value.strip) if value.respond_to?(:strip) && columns[column]&.options[:strip_tags] != false
        [column, value]
      end.to_h
      attributes.reject! { |k, _v| headers_added_by_import.include?(k) }

      yield attributes, index
    end
  end

  def row_count
    (spreadsheet.last_row - data_start_row) + 1
  end

  def nr_to_col(number)
    ('A'..'ZZ').to_a[number]
  end

  def attribute_names
    return columns.keys if !includes_header? || ignore_header?

    translated_header_names = cells_from_row(header_row)
    @header_names = translated_header_names.map do |name|
      col_for(name)&.first
    end
  end

  def header_names
    return columns.values.map(&:name) if !includes_header? || ignore_header?

    @header_names ||= cells_from_row(header_row)
  end
end
