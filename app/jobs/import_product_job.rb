class ImportProductJob < ApplicationJob
  queue_as :product

  def perform
    # Do something later
    Services::Import.product
  end
end
