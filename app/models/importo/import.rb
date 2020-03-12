# frozen_string_literal: true

module Importo
  class Import < ApplicationRecord
    include ActiveStorage::Downloading

    belongs_to :importo_ownable, polymorphic: true

    has_many :message_instances, as: :messagable

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
      audit_trail class: ResourceStateTransition, as: :resource if "ResourceStateTransition".safe_constantize

      state :importing
      state :scheduled
      state :completed
      state :failed
      state :reverted

      after_transition any => any do |imprt, transition|
        Importo.config.import_callback(imprt, transition.to_name)
      end

      after_transition any => :scheduled, do: :schedule_import
      after_transition any => :reverting, do: :schedule_revert

      event :schedule do
        transition new: :scheduled
      end

      event :import do
        transition new: :importing
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
      errors.add(:original, I18n.t('importo.errors.structure_invalid', invalid_headers: importer.invalid_header_names.join(', '))) unless importer.structure_valid?
    end

    def importer
      @importer ||= "#{kind.camelize}Importer".constantize.new(self)
    end

    private

    def schedule_import
      ImportJob.perform_later(id)
    end

    def schedule_revert
      RevertJob.perform_later(id)
    end
  end
end
