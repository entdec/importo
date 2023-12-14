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

  def convert_values(row)
    return row if row.instance_variable_get('@importo_converted_values')

    row.instance_variable_set('@importo_converted_values', true)

    columns.each do |k, col|
      next if col.proc.blank? || row[k].nil?

      attr = col.options[:attribute]

      row[k] = import.column_overrides[col.attribute] if import.column_overrides[col.attribute]

      if col.collection
        # see if the value is part of the collection  of (name, id) pairs, error if not.
        value = col.collection.find { |item| item.last == row[k] || item.first == row[k] }&.last
        raise StandardError, "#{row[k]} is not a valid value for #{col.name}" if value.nil? && !row[k].nil?
      else
        value ||= row[k]
      end

      if value.present? && col.proc
        proc = col.proc
        proc_result = instance_exec value, row, &proc
        value = proc_result if proc_result
      end
      value ||= col.options[:default]

      row[k] = value
    end
    row
  end

  #
  # Assists in pre-populating the record for you
  # It wil try and find the record by id, or initialize a new record with it's attributes set based on the mapping from columns
  #
  def populate(row, record = nil)
    raise 'No attributes set for columns' unless columns.any? { |_, v| v.options[:attribute].present? }

    row = convert_values(row)

    result = if record
               record
             else
               raise 'No model set' unless model

               model.find_or_initialize_by(id: row['id'])
             end

    attributes = {}
    cols_to_populate = columns.select do |_, v|
      v.options[:attribute].present?
    end

    cols_to_populate.each do |k, col|
      attr = col.options[:attribute]

      next unless row.key? k
      next if !row[k].present? && col.options[:default].nil?

      attributes = if !row[k].present? && !col.options[:default].nil?
                     set_attribute(attributes, attr, col.options[:default])
                   else
                     set_attribute(attributes, attr, row[k])
                   end
    end

    result.assign_attributes(attributes)

    result
  end

  #
  # Mangle the record before saving
  #
  def before_save(_record, _row)
    # Implement optionally in child class to mangle
  end

  #
  # Any updates that have to be done after saving
  #
  def after_save(_record, _row)
    # Implement optionally in child class to perform other updates
  end

  #
  # Does the actual import
  #
  def import!
    raise ArgumentError, 'Invalid data structure' unless structure_valid?

    run_callbacks(:import) do
    end

    signal = Signum.info(@import.importer.current_user,
                         { title: '', text: "Scheduling import of #{@import.original.filename}", sticky: true,
                           total: @import.importer.send(:row_count) })
    Signum::SendSignalsJob.perform_now(signal, true)

    batch = Sidekiq::Batch.new
    batch.description = 'Import Batch'
    # this will call "ImportJobCallback.new.on_complete" when all jobs are executed at least once irrespective of failure or success, not ideal with when we have set retry on a job
    # batch.on(:complete, Importo::ImportJobCallback, import_id: import.id, signal_id: signal.id)
    # this will call "ImportJobCallback.new.on_success" when all jobs are successfully executed
    # batch.on(:success, 'AnotherClass#method', 'uid' => current_user.id)

    batch.jobs do
      loop_data_rows do |attributes, index|
        Importo::ImportJob.perform_async(JSON.dump(attributes), index,
                                         import.id, signal.id)
      end
    end

    true
  rescue StandardError => e
    @import.result_message = "Exception: #{e.message}"
    Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(';')}"
    @import.failure!

    false
  end

  def process_data_row(attributes, index, last_attempt: true)
    run_callbacks(:row_import) do
    end
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
        after_save(record, attributes)
        duplicate_import = duplicate?(row_hash, record.id)
        raise Importo::DuplicateRowError if duplicate_import

        register_result(index, class: record.class.name, id: record.id, state: :success)
      end
      record
    rescue Importo::DuplicateRowError
      record_id = duplicate_import.results.find { |data| data['hash'] == row_hash }['id']
      register_result(index, id: record_id, state: :duplicate,
                             message: "Row already imported successfully on #{duplicate_import.created_at.to_date}")
      nil
    rescue StandardError => e
      raise e if e.is_a?(ActiveRecord::RecordNotFound) && !last_attempt

      errors = record.respond_to?(:errors) && record.errors.full_messages.join(', ')
      error_message = "#{e.message} (#{e.backtrace.first.split('/').last})"
      failure(attributes, record, index, e)
      register_result(index, class: record.class.name, state: :failure, message: error_message, errors: errors)
      nil
    end
  end

  private

  ##
  # Overridable failure method
  #
  def failure(_row, _record, index, exception)
    Rails.logger.error "#{exception.message} processing row #{index}: #{exception.backtrace.join(';')}"
  end

  def set_attribute(hash, path, value)
    tmp_hash = path.to_s.split('.').reverse.inject(value) { |h, s| { s => h } }
    hash.deep_merge(tmp_hash)
  end
end
