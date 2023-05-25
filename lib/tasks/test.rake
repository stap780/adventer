# -*- encoding : utf-8 -*-
namespace :xls do
    desc "тестировал xls"
  
    task create: :environment do
    puts "start create #{Time.now.to_s}"

    url = "https://10984739f41524279cdffcb8fc1b8d9a:e97c42aebb33746c6732d3095b2fee34@shop.candy.ru/admin/properties.json?per_page=1000"
    response = RestClient.get(url)
    data = JSON.parse(response)
    p = Axlsx::Package.new
    wb = p.workbook
    wb.add_worksheet(name: 'Навигация по каталогу') do |sheet|
        sheet.add_row ['title', 'permalink']
        data.each do |d|
            title = d['title']
            permalink = d['permalink']
            sheet.add_row [title, permalink]
        end
    end
    stream = p.to_stream
    file_path = Services::Import::DownloadPath+"/public/property_file.xlsx"
    File.open(file_path, 'wb') { |f| f.write(stream.read) }

      puts "end create #{Time.now.to_s}"
    end
  
  
  end
  