# frozen_string_literal: true

module Importo
  class Import < ApplicationRecord
    include AASM

    #belongs_to :user

    has_many :message_instances, as: :messagable

    #delegate :channel, :retailer, :company, to: :user

    #validates :user, presence: true
    validates :kind, presence: true
    validates :file_name, presence: true
    validate :content_validator

    aasm column: :state, no_direct_assignment: true do
      state :new, initial: true

      state :importing
      state :scheduled, after_enter: ->(imprt) { ImportJob.perform_later(imprt.id) }
      state :completed, after_enter: ->(imprt) { ImportCompleteJob .perform_later(imprt.id) }
      state :failed, after_enter: ->(imprt) { ImportFailureJob.perform_later(imprt.id) }

      event :schedule do
        transitions from: :new, to: :scheduled
      end

      event :import do
        transitions from: :new, to: :importing
        transitions from: :scheduled, to: :importing
      end

      event :complete do
        transitions from: :importing, to: :completed
      end

      event :failure do
        transitions from: :importing, to: :failed
      end
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
