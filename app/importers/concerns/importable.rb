# frozen_string_literal: true

require "active_support/concern"

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
    return row if row.instance_variable_get(:@importo_converted_values)

    row.instance_variable_set(:@importo_converted_values, true)

    columns.each do |k, col|
      next if col.proc.blank? || row[k].nil?

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
    raise "No attributes set for columns" unless columns.any? { |_, v| v.options[:attribute].present? }

    row = convert_values(row)

    result = if record
      record
    else
      raise "No model set" unless model

      model.find_or_initialize_by(id: row["id"])
    end

    attributes = {}
    cols_to_populate = columns.select do |_, v|
      v.options[:attribute].present?
    end

    cols_to_populate = cols_to_populate.deep_symbolize_keys

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
  # Callbakcs
  #
  def before_build(_record, _row)
  end

  def around_build(_record, _row)
    yield
  end

  def after_build(_record, _row)
  end

  def before_save(_record, _row)
  end

  def around_save(_record, _row)
    yield
  end

  def after_save(_record, _row)
  end

  def before_validate(_record, _row)
  end

  def around_validate(_record, _row)
    yield
  end

  def after_validate(_record, _row)
  end

  #
  # Does the actual import
  #
  def import!
    raise ArgumentError, "Invalid data structure" unless structure_valid?

    batch = Importo.config.batch_adapter.new
    batch.description = "#{import.original.filename} - #{import.kind}"
    batch.properties = {import_id: import.id}
    batch.on_success("Importo::ImportJobCallback")

    batch.add do
      column_with_delay = columns.select { |k, v| v.delay.present? }
      loop_data_rows do |attributes, index|
        if column_with_delay.present?
          delay = column_with_delay.filter_map do |k, v|
            next unless attributes[k].present?
            v.delay.call(attributes[k])
          end
        end
        Importo::ImportJob.set(wait_until: (delay.max * index).seconds.from_now).perform_async(JSON.dump(attributes), index, import.id) if delay.present?
        Importo::ImportJob.perform_async(JSON.dump(attributes), index, import.id) unless delay.present?
      end
    end

    true
  rescue => e
    @import.result_message = "Exception: #{e.message}"
    Rails.logger.error "Importo exception: #{e.message} backtrace #{e.backtrace.join(";")}"
    @import.failure!

    false
  end

  def process_data_row(attributes, index, last_attempt: true)
    record = nil
    row_hash = Digest::SHA256.base64digest(attributes.inspect)
    duplicate_import = nil

    run_callbacks :row_import do
      record = nil

      ActiveRecord::Base.transaction do
        register_result(index, hash: row_hash, state: :processing)

        before_build(record, attributes)
        around_build(record, attributes) do
          record = build(attributes)
        end
        after_build(record, attributes)

        before_validate(record, attributes)
        around_validate(record, attributes) do
          record.validate!
        end
        after_validate(record, attributes)

        model.with_advisory_lock(:importo) do
          before_save(record, attributes)
          around_save(record, attributes) do
            record.save!
          end
          after_save(record, attributes)
        end

        duplicate_import = duplicate?(row_hash, record.id)
        raise Importo::DuplicateRowError if duplicate_import

        register_result(index, class: record.class.name, id: record.id, state: :success)
      end
    end

    record
  rescue Importo::DuplicateRowError
    record_id = duplicate_import.results.find { |data| data["hash"] == row_hash }["id"]
    register_result(index, id: record_id, state: :duplicate,
      message: "Row already imported successfully on #{duplicate_import.created_at.to_date}")

    run_callbacks(:row_import, :after)
    nil
  rescue Importo::RetryError => e
    raise e unless last_attempt

    errors = record.respond_to?(:errors) && record.errors.full_messages.join(", ")
    error_message = "#{e.message} (#{e.backtrace.first.split("/").last})"
    failure(attributes, record, index, e)
    register_result(index, class: record.class.name, state: :failure, message: error_message, errors: errors)
    nil
  rescue => e
    # We rescue ActiveRecord::RecordNotUnique here, due to how transactions work, some row imports may have started the transaction and the current row doesn't see the results
    raise Importo::RetryError.new("ActiveRecord::RecordNotUnique", 2) if !last_attempt && e.is_a?(ActiveRecord::RecordNotUnique)
    errors = record.respond_to?(:errors) && record.errors.full_messages.join(", ")
    error_message = "#{e.message} (#{e.backtrace.first.split("/").last})"
    failure(attributes, record, index, e)
    register_result(index, class: record.class.name, state: :failure, message: error_message, errors: errors)
    run_callbacks(:row_import, :after)
    nil
  end

  private

  ##
  # Overridable failure method
  #
  def failure(_row, _record, index, exception)
    Rails.logger.error "#{exception.message} processing row #{index}: #{exception.backtrace.join(";")}"
  end

  def set_attribute(hash, path, value)
    tmp_hash = path.to_s.split(".").reverse.inject(value) { |h, s| {s => h} }
    hash.deep_merge(tmp_hash)
  end

  # Only when the block returns a record created in this import, it returns that record, otherwise nil
  #
  #  record ||= only_current_import! do
  #    User.find_by(email: row[:email].downcase) if row[:email].present?
  #  end
  #
  # Only if the user was created this import will the block return the user found.
  #
  # @return [Object]
  def only_current_import!(&block)
    ActiveRecord::Base.uncached do
      record = yield
      record if record && @import.results.where("details->>'state' = ?", "success").where("details->>'id' = ? ", record.id).exists?
    end
  end
end
