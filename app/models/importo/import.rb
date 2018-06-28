# frozen_string_literal: true

module Importo
  class Import < ApplicationRecord
    belongs_to :importo_ownable, polymorphic: true

    has_many :message_instances, as: :messagable

    validates :kind, presence: true
    validates :file_name, presence: true
    validate :content_validator

    state_machine :state, initial: :new do
      state :importing
      state :scheduled
      state :completed
      state :failed

      after_transition any => any do |imprt, transition|
        Importo.config.import_callback(imprt, transition.to_name)
      end

      after_transition any => :scheduled, do: :schedule_import

      event :schedule do
        transition new: :scheduled
      end

      event :import do
        transition new: :importing
        transition scheduled: :importing
      end

      event :complete do
        transition importing: :completed
      end

      event :failure do
        transition importing: :failed
      end
    end

    def content_validator
      errors.add(:file_name, I18n.t('import.errors.structure_invalid', invalid_headers: importer.invalid_header_names.join(', '))) unless importer.structure_valid?
    end

    def importer
      @importer ||= "#{kind.camelize}Importer".constantize.new(self)
    end

    private

    def schedule_import
      ImportJob.perform_later(id)
    end
  end
end
