if !defined?(Sidekiq::Batch)
  module Sidekiq
    class Batch
      def self.new(*)
        raise NotImplementedError, "Sidekiq::Batch is not available. Please install the sidekiq-pro or sidekiq-batch gem."
      end
    end
  end
end

module Importo
  class SidekiqBatchAdapter
    attr_reader :description
    attr_accessor :properties
    attr_writer :instance

    def initialize
      @instance = Sidekiq::Batch.new
    end

    delegate :description=, to: :@instance

    def on_success(job)
      @instance.on(:success, job.constantize, properties)
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
      def find(id)
        instance = new
        instance.instance = Sidekiq::Batch.new(id)
        instance
      end
    end
  end
end
