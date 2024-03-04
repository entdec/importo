# frozen_string_literal: true

module Importo
  class Import < Importo::ApplicationRecord
    # include ActiveStorage::Downloading
    attr_accessor :checked_columns
    belongs_to :importo_ownable, polymorphic: true

    has_many :message_instances, as: :messagable
    has_many :results, class_name: 'Importo::Result', dependent: :delete_all

    validates :kind, presence: true
    validates :original, presence: true
    validate :content_validator
    begin
      has_one_attached :original
      has_one_attached :result
    rescue NoMethodError
      # Weird loading sequence error, is fixed by the lib/importo/helpers
    end

    state_machine :state, initial: :concept do
      state :confirmed
      state :importing
      state :scheduled
      state :completed
      state :failed
      state :reverted

      after_transition any => any do |imprt, transition|
        imprt.importer.state_changed(imprt, transition)
      end

      after_transition any => :scheduled, do: :schedule_import
      after_transition any => :reverting, do: :schedule_revert

      event :schedule do
        transition confirmed: :scheduled
      end

      event :confirm do
        transition concept: :confirmed
      end

      event :import do
        transition confirmed: :importing
        transition scheduled: :importing
        transition failed: :importing
      end

      event :complete do
        transition importing: :completed
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
                   I18n.t('importo.errors.structure_invalid',
                          invalid_headers: importer.invalid_header_names.join(', ')))
      end
    rescue StandardError => e
      errors.add(:original, I18n.t('importo.errors.parse_error', error: e.message))
    end

    def importer
      @importer ||= "#{kind.camelize}Importer".constantize.new(self)
    end

    private

    def schedule_import
      ImportService.perform_later(import: self, checked_columns: self.checked_columns)
    end

    def schedule_revert
      RevertService.perform_later(import: self)
    end
  end
end
