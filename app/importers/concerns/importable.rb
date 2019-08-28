
# frozen_string_literal: true

require 'active_support/concern'

module Importable
  extend ActiveSupport::Concern

  #
  # Build a record based on the row, when you override build, depending on your needs you will need to
  # call populate yourself, or skip this altogether.
  #
  def build(row)
    populate(row)
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

      row[k] = import.column_overrides[col.attribute] if import.column_overrides[col.attribute]

      if col.collection
        # see if the value is part of the collection  of (name, id) pairs, error if not.
        value = col.collection.find { |item| item.last == row[k] || item.first == row[k] }&.last
        raise StandardError, "#{row[k]} is not a valid value for #{col.name}" if value.nil? && row[k].present?
      else
        value ||= row[k]
      end

      if value.present? && col.proc
        proc = col.proc
        proc_result = instance_exec value, record, row, &proc
        value = proc_result if proc_result
      end
      value ||= col.options[:default]

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

    @import.result_message = I18n.t('importo.importers.result_message', nr: results.compact.count, of: results.count, start_row: data_start_row)
    @import.complete!
  rescue StandardError => e
    @import.result_message = "Exception: #{e.message}"
    Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(';')}"
    @import.failure!
  end

  private

  ##
  # Overridable failure method
  #
  def failure(_row, _record, index, exception)
    Rails.logger.error "#{exception.message} processing row #{index}: #{exception.backtrace.join(';')}"
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

  def set_attribute(hash, path, value)
    tmp_hash = path.split('.').reverse.inject(value) { |h, s| { s => h } }
    hash.deep_merge(tmp_hash)
  end
end
