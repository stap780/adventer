class ImportExcelPriceJob < ApplicationJob
  queue_as :excel

  rescue_from(StandardError) do |exception|
    puts 'ImportExcelPriceJob rescuing standard error: ' + exception.message
  end

  discard_on(StandardError) do |job, error|
           #AnyExceptionNotifier.caught(error) - это из примера
    # puts job.inspect.to_s
    # puts job.arguments.to_s
    job.arguments.first.update!(file_status: 'end')
  end

  after_perform do |job|
    puts 'ImportExcelPriceJob after perform'
  end

  def perform(excel_price)
    # Do something later
    # puts "during ImportExcelPriceJob perform"
    Services::Import.excel_price(excel_price)
      # raise StandardError, "error during ImportExcelPriceJob perform"
  end
end
