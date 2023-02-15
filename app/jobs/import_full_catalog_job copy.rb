class ImportFullCatalogJob < ApplicationJob
  queue_as :excel

  def perform
    # Do something later
    Services::Import.load_all_catalog_xml
  end
end
