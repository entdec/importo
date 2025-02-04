if !defined?(Sidekiq::Batch)
  module Sidekiq
    class Batch
      def self.new(*)
        raise NotImplementedError, "Sidekiq::Batch is not available. Please install the sidekiq-pro or sidekiq-batch gem."
      end
    end
  end
end

require_relative "../../../app/jobs/importo/import_job"

module Importo
  class SidekiqBatchAdapter
    attr_reader :description
    attr_accessor :properties
    attr_writer :instance

    delegate :description=, :status, to: :@instance

    def initialize
      @instance = Sidekiq::Batch.new
    end

    def on_success(job)
      @instance.on(:complete, job.constantize, properties)
    end

    def add
      @instance.jobs do
        yield
      end
    end

    def finished?
      @instance.status.complete?
    end

    class << self
      def import_job_base_class
        Object
      end

      def find(id)
        instance = new
        instance.instance = Sidekiq::Batch.new(id)
        instance
      end
    end

    module ImportJobIncludes
      extend ActiveSupport::Concern

      included do
        queue_as Importo.config.queue_name
        sidekiq_options retry: 5

        sidekiq_retries_exhausted do |msg, _e|
          attributes = msg["args"][0]
          index = msg["args"][1]
          import_id = msg["args"][2]

          execute_row(attributes, index, import_id, true, msg["bid"])
        end

        sidekiq_retry_in do |_count, exception, _jobhash|
          case exception
          when Importo::RetryError
            exception.delay
          end
        end
      end
    end
  end
end

Importo::ImportJob.send(:include, Sidekiq::Job)
Importo::ImportJob.send(:include, Importo::SidekiqBatchAdapter::ImportJobIncludes)
