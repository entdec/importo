module Importo
  class ApplicationJob < ActiveJob::Base
    include GoodJob::ActiveJobExtensions::Batches if Importo.config.batch_adapter.name == "GoodJob::Batch"
  end
end
