class ImportProductJob < ApplicationJob
  queue_as :product

  def perform
    Services::Import.product
  end
end
