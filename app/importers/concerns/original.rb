
# frozen_string_literal: true

require 'active_support/concern'

module Original
  extend ActiveSupport::Concern

  def original
    return @original if @original
    return unless import&.original&.attached?

    @blob = import.original
    @original = Tempfile.new(['ActiveStorage', import.original.filename.extension_with_delimiter])
    @original.binmode
    download_blob_to @original
    @original.flush
    @original.rewind
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
    col = columns.detect do |k, v|
      v.name == translated_name || k == translated_name
    end
    col
  end

  private

  def headers_added_by_import
    %w[import_state import_created_id import_message import_errors].map(&:dup)
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
      row = cells_from_row(index)
      attributes = Hash[[attribute_names, row].transpose]
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
      col_for(name).first
    end
  end

  def header_names
    return columns.values.map(&:name) if !includes_header? || ignore_header?

    @header_names ||= cells_from_row(header_row)
  end
end
