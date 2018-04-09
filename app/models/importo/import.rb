# frozen_string_literal: true

module Importo
  class Import < ApplicationRecord
    belongs_to :user

    has_many :message_instances, as: :messagable

    delegate :channel, :retailer, :company, to: :user

    validates :user, presence: true
    validates :kind, presence: true
    validates :file_name, presence: true
    validate :content_validator

    state_machine initial: :new do
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

      after_transition(any => :scheduled) { |imprt, _transition| ImportJob.perform_later(imprt.id) }
      after_transition(any => :completed) { |imprt, _transition| ImportCompleteJob .perform_later(imprt.id) }
      after_transition(any => :failed)    { |imprt, _transition| ImportFailureJob.perform_later(imprt.id) }
    end

    def content_validator
      errors.add(:file_name, I18n.t('import.errors.structure_invalid', invalid_headers: importer.invalid_header_names.join(', '))) unless importer.structure_valid?
    end

    def importable_fields
      importer.fields
    end

    def importer
      @importer ||= "#{kind.camelize}Importer".constantize.new(self)
    end
  end
end
