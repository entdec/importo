# frozen_string_literal: true

module Importo
  class Import < Importo::ApplicationRecord
    # include ActiveStorage::Downloading

    belongs_to :importo_ownable, polymorphic: true

    has_many :message_instances, as: :messagable
    has_many :results, class_name: "Importo::Result", dependent: :delete_all

    validates :kind, presence: true
    validates :original, presence: true
    validate :content_validator

    begin
      has_one_attached :original
      has_one_attached :result
    rescue NoMethodError
      # Weird loading sequence error, is fixed by the lib/importo/helpers
    end

    state_machine :state, initial: :new do
      state :importing
      state :scheduled
      state :completed
      state :failed
      state :reverted

      after_transition any => any do |imprt, transition|
        imprt.importer.state_changed(imprt, transition)
      end

      after_transition any => :scheduled, :do => :schedule_import
      after_transition any => :reverting, :do => :schedule_revert

      event :schedule do
        transition new: :scheduled
      end

      event :import do
        transition new: :importing
        transition scheduled: :importing
        transition failed: :importing
      end

      event :complete do
        transition importing: :completed, if: ->(import) { import.no_processing? && import.results.count == import.importer.send(:row_count) }
      end

      event :failure do
        transition any => :failed
      end

      event :revert do
        transition completed: :reverting
      end

      event :revert do
        transition reverting: :reverted
      end
    end

    def can_revert?
      importer.allow_revert? && super
    end

    def allow_export?
      importer.class.allow_export?
    end

    def content_validator
      unless importer.structure_valid?
        errors.add(:original,
          I18n.t("importo.errors.structure_invalid",
            invalid_headers: importer.invalid_header_names.join(", ")))
      end
    rescue => e
      Rails.logger.info "Importo failed excpetion: #{e.message} backtrace #{e.backtrace.join(";")}"
      errors.add(:original, I18n.t("importo.errors.parse_error", error: e.message))
    end

    def importer
      @importer ||= "#{kind.camelize}Importer".constantize.new(self)
    end

    def failure?
      results.where("details @> ?", '{"state":"failure"}').any?
    end

    def no_failure?
      results.where("details @> ?", '{"state":"failure"}').none?
    end

    def success?
      results.where("details @> ?", '{"state":"success"}').any?
    end

    def no_succes?
      results.where("details @> ?", '{"state":"success"}').none?
    end

    def processing?
      results.where("details @> ?", '{"state":"processing"}').any?
    end

    def no_processing?
      results.where("details @> ?", '{"state":"processing"}').none?
    end

    private

    def schedule_import
      ImportScheduleJob.perform_in(5.seconds, id)
    end

    def schedule_revert
      ImportRevertJob.perform_in(5.seconds, id)
    end
  end
end
