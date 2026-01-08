module Importo
  class ApplicationJob < ActiveJob::Base
    include GoodJob::ActiveJobExtensions::Batches if Importo.good_job?
  end
end
