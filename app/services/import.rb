class Services::Import

  DownloadPath = Rails.env.development? ? "#{Rails.root}" : "/var/www/adventer/shared"
  MainText = 'Общество с ограниченной ответственностью «Адвентер»

  188802, ЛО, г.Выборг, ул. Данилова, д.15 корп.1, оф.248
        
  Тел. 8 800 550 13 14
  эл.почта: info@adventer.su
  Сайт:  www.adventer.su
        
  ИНН: 4704097388
  КПП: 470401001
  ОГРН: 1154704001264
  ОКПО: 23384032
  ОКАТО: 41417000000
  ОКВЭД: 46.49, 73.11
  ОКОГУ: 4210014
  ОКТМО: 41615101001
        
  Расчетный счет: 40702810555390000762
  Кор. счет: 30101810500000000653
  БИК: 044030653
  Банк: Северо-Западный банк ПАО Сбербанк г. Санкт-Петербург
        
        
  Упрощенная система налогообложения  – без НДС.'


  def self.product
    require 'open-uri'
    puts '=====>>>> СТАРТ InSales EXCEL '+Time.now.to_s
    url = "https://adventer.su/marketplace/2416318.xls"
		filename = url.split('/').last
    download = open(url)
		download_path = Services::Import::DownloadPath+"/public/"+filename
		IO.copy_stream(download, download_path)
    spreadsheet = Roo::Excel.new(download_path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      sdesc = row["Краткое описание"].present? ? Product.strip_html(row["Краткое описание"]) : nil
      fdesc = row["Полное описание"].present? ? Product.strip_html(row["Полное описание"]) : ''
      desc = sdesc.present? ? sdesc : fdesc
      save_data = {
                  insvarid: row["ID варианта"].to_i,
                  sku: row["Артикул"].to_s,
                  title: row["Название товара или услуги"].to_s,
                  desc: desc,
                  price: row["Цена продажи"].to_i,
                  insid: row["ID товара"].to_i
                }

      search_product = Product.find_by_insvarid(save_data[:insvarid])
      product = search_product.present? ? search_product : 
                                          Product.create!(save_data)
      puts "import product id - "+product.id.to_s
      images = row["Изображения"].present? ? row["Изображения"].split(' ').reject(&:blank?) : []
      # puts "images кол-во - #{images.count.to_s}"
      # puts images.to_s
      if images.present?
        images.first(1).each do |img_link|
          # puts img_link
          img_filename = img_link.split('/').last.split('.').first
          if product.images.size < 3 && !product.images.select{|im| im.filename.to_s == img_filename }.present?
            file = Services::Import.download_remote_file(img_link)
            product.images.attach(io: file, filename: img_filename, content_type: "image/jpg")
          end
        end
      end

      break if Rails.env.development? && i == 100
    end
    # Product.where(quantity: nil).update_all(quantity: 0)
    File.delete(download_path) if File.file?(download_path).present?

    puts '=====>>>> FINISH InSales EXCEL '+Time.now.to_s

    current_process = "=====>>>> FINISH InSales EXCEL - #{Time.now.to_s} - Закончили обновление каталога товаров"
  	# ProductMailer.notifier_process(current_process).deliver_now
  end
  
  def self.excel_price(excel_price)
    require 'open-uri'
    puts "=====>>>> СТАРТ import excel_price #{Time.now.to_s}"
    
    puts "=====>>>> СТАРТ import all_offers #{Time.now.to_s}"
    all_offers = Nokogiri::XML(File.open(Services::Import::DownloadPath+"/public/1923917.xml")).xpath("//offer")
    puts "=====>>>> СТАРТ import all_offers #{Time.now.to_s}"    
    
    excel_price.update!(file_status: 'process')
    File.delete(Services::Import::DownloadPath+"/public/#{excel_price.id.to_s}_file.xlsx") if File.file?(Services::Import::DownloadPath+"/public/#{excel_price.id.to_s}_file.xlsx").present?
    url = excel_price.link
		filename = url.split('/').last
    download = open(url)
		download_path = Services::Import::DownloadPath+"/public/"+filename
		IO.copy_stream(download, download_path)
    data = Nokogiri::XML(open(download_path))

    categories = data.xpath("//category").map{|c| {id: c["id"], title: c.text, parent_id: c["parentId"]}}

    all_categories = Services::Import.collect_main_list_cat_info(categories)

    select_main_cat = all_categories.map{|c| c[:parent_id]}.all?(&:nil?) ? nil : all_categories.select{|c| c[:parent_id] == nil}

    categories_for_list = select_main_cat.present? ? all_categories.select{|c| c[:parent_id] == select_main_cat[0][:id]} : 
                                                     all_categories

    p = Axlsx::Package.new
    wb = p.workbook
    # style section
    s = wb.styles
    header = s.add_style sz: 16, b: true, alignment: { horizontal: :center, vertical: :center } #bg_color: 'DD',
    header_second =  s.add_style bg_color: 'E6F1F1', sz: 14, b: true, alignment: { horizontal: :center, vertical: :center }
    tbl_header = s.add_style b: true, alignment: { horizontal: :center, vertical: :center  }
    ind_header = s.add_style bg_color: 'CDE3E3', sz: 16, b: true, alignment: { horizontal: :center, vertical: :center , indent: 1 }
    col_header = s.add_style bg_color: 'FFDFDEDF', b: true, alignment: { horizontal: :center , vertical: :center }
    label      = s.add_style alignment: { indent: 1 }
    money      = s.add_style alignment: { horizontal: :center , vertical: :center }, format_code: "# ##0\ ₽", border: Axlsx::STYLE_THIN_BORDER, b: true
    main_label = s.add_style bg_color: 'E6F1F1', alignment: { horizontal: :center, vertical: :center, indent: 0, wrap_text: true }, b: true
    pr_title   = s.add_style alignment: { horizontal: :left , vertical: :center, indent: 1, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER, b: true
    pr_sku   = s.add_style alignment: { horizontal: :center , vertical: :center, indent: 1, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    pr_descr   = s.add_style alignment: { horizontal: :left , vertical: :center, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER, sz: 10
    pr_pict    = s.add_style alignment: { horizontal: :center , vertical: :center },border: Axlsx::STYLE_THIN_BORDER
    pr_index   = s.add_style alignment: { horizontal: :center , vertical: :center, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    back_button = s.add_style alignment: { horizontal: :center , vertical: :center, wrap_text: true }, bg_color: 'B4D5D5', sz: 14
    bg_w = s.add_style bg_color: 'FFFFFF'
    but_rekv = s.add_style bg_color: 'FFFFFF', alignment: { horizontal: :left , vertical: :top, indent: 1, wrap_text: true }, fg_color: '7F7F7F'
    notice_main_label = s.add_style bg_color: 'FFFFFF', alignment: { horizontal: :center , vertical: :top }
    notice_label = s.add_style bg_color: 'FDE9D9', alignment: { horizontal: :center , vertical: :center}, b: true, sz: 12
    notice_b = s.add_style bg_color: 'FDE9D9', alignment: { horizontal: :center , vertical: :center }, sz: 12
    if excel_price.rrc == true
      pr_style = [nil,pr_index,pr_pict,pr_title,pr_sku,pr_descr,money,money]
    else
      pr_style = [nil,pr_index,pr_pict,pr_title,pr_sku,pr_descr,money]
    end
    # end style section

    start_array_string = {0=>'B6',1=>'D6',2=>'F6',3=>'H6',4=>'B8',5=>'D8',6=>'F8',7=>'H8',8=>'B10',9=>'D10',10=>'F10',11=>'H10'}
    # end_array = {0=>'C7',1=>'E7',2=>'G7',3=>'I7',4=>'C9',5=>'E9',6=>'G9',7=>'I9',8=>'C11',9=>'E11',10=>'G11',11=>'I11'}
    start_array = { 0=>[1,5],1=>[3,5],2=>[5,5],3=>[7,5],
                    4=>[1,7],5=>[3,7],6=>[5,7],7=>[7,7],
                    8=>[1,9],9=>[3,9],10=>[5,9],11=>[7,9],
                    12=>[1,11],13=>[3,11],14=>[5,11],15=>[7,11],
                    16=>[1,13],17=>[3,13],18=>[5,13],19=>[7,13],
                    20=>[1,15],21=>[3,15],22=>[5,15],23=>[7,15],
                    24=>[1,17],25=>[3,17],26=>[5,17],27=>[7,17]}
    end_array = { 0=>[2,6],1=>[4,6],2=>[6,6],3=>[8,6],
                  4=>[2,8],5=>[4,8],6=>[6,8],7=>[8,8],
                  8=>[2,10],9=>[4,10],10=>[6,10],11=>[8,10],
                  12=>[2,12],13=>[4,12],14=>[6,12],15=>[8,12],
                  16=>[2,14],17=>[4,14],18=>[6,14],19=>[8,14],
                  20=>[2,16],21=>[4,16],22=>[6,16],23=>[8,16],
                  24=>[2,18],25=>[4,18],26=>[6,18],27=>[8,18]}
    notice_text_main_sheet = Axlsx::RichText.new
    notice_text_main_sheet.add_run('Подсказка: ', b: true, color: 'EA4488')
    notice_text_main_sheet.add_run('для того чтобы открыть нужную категорию нажмите на название или вкладку')
  
    puts "start create main sheet"
    wb.add_worksheet(name: 'Навигация по каталогу') do |sheet|
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','Каталог продукции','','','','','','','','Реквизиты',''], height: 50, style: [bg_w,header,bg_w,bg_w,bg_w,bg_w,bg_w,bg_w,bg_w,header,bg_w]
      sheet.add_row ['',notice_text_main_sheet,'','','','','','','','',''], height: 20, style: notice_main_label

      count_rows = categories_for_list.count < 4 ? categories_for_list.count : (categories_for_list.count/4).ceil
      Array(0..count_rows).each do |arr|
        sheet.add_row ['','','','','','','','','','',''], height: 150, style: bg_w
        sheet.add_row ['','','','','','','','','','',''], height: 40, style: [bg_w,nil,bg_w,nil,bg_w,nil,bg_w,nil,bg_w,bg_w,bg_w]
      end
      sheet.add_row ['','','','','','','','','','',''], height: 80, style: bg_w
      categories_for_list.each_with_index do |cat, index|
          column_start = start_array[index][0]
          row_start = start_array[index][1]
          column_end = start_array[index][0]
          row_end = start_array[index][1]

          sheet.rows[row_end+1].cells[column_end].value = cat[:title]
          sheet.rows[row_end+1].cells[column_end].style = main_label
          file_name = cat[:id]
          image = Services::Import.process_image(cat[:image], file_name)
          sheet.add_image(image_src: image, :noSelect => true, :noMove => true) do |image|
            image.width = 200
            image.height = 200
            image.start_at start_array[index]
            # image.start_at start_array[index][0], start_array[index][1]
            # image.end_at start_array[index][0], start_array[index][1]
          end
          sheet.add_hyperlink( location: "'#{cat[:title].at(0..30).gsub('/',',')}'!A1", target: :sheet, ref: sheet.rows[row_end+1].cells[column_end] )
      end

      sheet.column_widths 2,25,2,25,2,25,2,25,10,50,10
      sheet.merge_cells('B4:H4')
      sheet.merge_cells('B5:H5')
      sheet.merge_cells('J6:J11')
      logo_image = Services::Import::DownloadPath+"/public/adventer_logo_excel.jpg"
      sheet.add_image(image_src: logo_image, start_at: 'A1', end_at: 'L4')
      sheet['J6'].value = Services::Import::MainText
      sheet['J6'].style = but_rekv
      puts "finish add collections to main sheet"
    end
    puts "finish create main sheet"

    # row_index_for_titles_array = []
    puts "start create seconds collections sheets"
    categories_for_list.each_with_index do |cat, index|
      row_index_for_titles_array = []
      puts "start create sheet -> "+cat[:title]
      notice_text = Axlsx::RichText.new
      notice_text.add_run('Подсказка: ', :b => true)
      notice_text.add_run('для того чтобы открыть позицию на сайте нажмите на наименование/фото товара')
      wb.add_worksheet(name: cat[:title].at(0..30).gsub('/',',').gsub('?','')) do |sheet|
        sheet.add_row ['','<= НА ГЛАВНУЮ','', cat[:title]], style: [nil,back_button,back_button,ind_header], height: 30
        sheet.add_row ['',notice_text,'','','','',''], style: [nil,notice_b,notice_label,notice_b,notice_b,notice_b,notice_b,notice_b], height: 20
        second_cats = all_categories.select{ |c| c[:parent_id] == cat[:id] }
        if second_cats.present?
          second_cats.each do |s_cat|
            if excel_price.our_product == true
              cat_products =  Rails.env.development? ? Services::Import.collect_our_product_ids(cat[:id]).take(15) :
              Services::Import.collect_our_product_ids(cat[:id])
            else
              cat_products =  Rails.env.development? ? Services::Import.collect_product_ids(cat[:id]).take(15) :
                                                      Services::Import.collect_product_ids(cat[:id])
            end
              if cat_products.present?
              cat_title_row = sheet.add_row ['',s_cat[:title]], style: [nil,header_second], height: 30
              row_index_for_titles_array.push(cat_title_row.row_index+1)
              if excel_price.rrc == true
                sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена со скидкой','Цена РРЦ'], style: tbl_header, height: 20
              else
                sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена'], style: tbl_header, height: 20
              end
                cat_products.each_with_index do |pr_id, index|
                pr = all_offers.select{|offer| offer if offer["id"] == pr_id.to_s}[0]
                if pr.present?
                  data = Services::Import.collect_product_data_from_xml(pr,excel_price)
                  if excel_price.rrc == true
                    discount = data[:price]-data[:price]*0.2
                    pr_data = ['',(index+1).to_s,'',data[:title],data[:sku],data[:desc],discount,data[:price]]
                  else
                    pr_data = ['',(index+1).to_s,'',data[:title],data[:sku],data[:desc],data[:price]]
                  end
                  pr_row = sheet.add_row pr_data, style: pr_style, height: 150
                  hyp_ref = "D#{(pr_row.row_index+1).to_s}"
                  sheet.add_hyperlink location: data[:url], ref: hyp_ref
                  sheet.add_image(image_src: data[:image], :noSelect => true, :noMove => true, hyperlink: data[:url]) do |image|
                    image.start_at 2, pr_row.row_index
                    image.end_at 3, pr_row.row_index+1
                    image.anchor.from.rowOff = 10_000
                    image.anchor.from.colOff = 10_000
                  end
                end           
              end
            end
          end
        end
        if !second_cats.present?
          if excel_price.our_product == true
            cat_products =  Rails.env.development? ? Services::Import.collect_our_product_ids(cat[:id]).take(15) :
            Services::Import.collect_our_product_ids(cat[:id])
          else
            cat_products =  Rails.env.development? ? Services::Import.collect_product_ids(cat[:id]).take(15) :
                                                    Services::Import.collect_product_ids(cat[:id])
          end
          if cat_products.present?
            cat_title_row = sheet.add_row ['',cat[:title]], style: [nil,header_second], height: 30
            row_index_for_titles_array.push(cat_title_row.row_index+1)
            if excel_price.rrc == true
              sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена со скидкой 20%','Цена РРЦ'], style: tbl_header, height: 20
            else
              sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена'], style: tbl_header, height: 20
            end
            cat_products.each_with_index do |pr_id, index|
              pr = all_offers.select{|offer| offer if offer["id"] == pr_id.to_s}[0]
              if pr.present?
                  data = Services::Import.collect_product_data_from_xml(pr,excel_price)
                  if excel_price.rrc == true
                    discount = data[:price]-data[:price]*0.2
                    pr_data = ['',(index+1).to_s,'',data[:title],data[:sku],data[:desc],discount,data[:price]]
                  else
                    pr_data = ['',(index+1).to_s,'',data[:title],data[:sku],data[:desc],data[:price]]
                  end
                  #puts pr_data.to_s if pr['id'] == '139020547'
                  pr_row = sheet.add_row pr_data, style: pr_style, height: 150
                  # puts "pr_row.row_index - "+pr_row.row_index.to_s
                  hyp_ref = "D#{(pr_row.row_index+1).to_s}"
                  # puts hyp_ref.to_s
                  sheet.add_hyperlink location: data[:url], ref: hyp_ref

                  sheet.add_image(image_src: data[:image], :noSelect => true, :noMove => true, hyperlink: data[:url]) do |image|
                    image.start_at 2, pr_row.row_index
                    image.end_at 3, pr_row.row_index+1
                    image.anchor.from.rowOff = 10_000
                    image.anchor.from.colOff = 10_000
                  end
              end          
            end
          end
        end

        sheet.merge_cells("B1:C1")
        if excel_price.rrc == true
          sheet.merge_cells("D1:H1")
          sheet.merge_cells("B2:H2")
        else
          sheet.merge_cells("D1:G1")
          sheet.merge_cells("B2:G2")
        end
        sheet.add_hyperlink( location: "'Навигация по каталогу'!A7", target: :sheet, ref: 'B1' )
        if excel_price.rrc == true
        sheet.column_widths 2,10,25,40,40,40,30,30,2
        else
        sheet.column_widths 2,10,25,40,40,40,30,2
        end
        puts "row_index_for_titles_array => "+row_index_for_titles_array.to_s
        if excel_price.rrc == true
        merge_ranges = row_index_for_titles_array.map{|a| "B"+a.to_s+":"+"H"+a.to_s }
        else
          merge_ranges = row_index_for_titles_array.map{|a| "B"+a.to_s+":"+"G"+a.to_s }
        end
        merge_ranges.uniq.each { |range| sheet.merge_cells(range) }
        sheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.x_split = 1
          pane.y_split = 2
        end
      end
      puts "finish create sheet -> "+cat[:title]
    end
    puts "finish create seconds collections sheets"

    stream = p.to_stream
    file_path = Services::Import::DownloadPath+"/public/#{excel_price.id.to_s}_file.xlsx"
    File.open(file_path, 'wb') { |f| f.write(stream.read) }

    excel_price.update!(file_status: 'end') if File.file?(file_path).present?
    File.delete(download_path) if File.file?(download_path).present?

    puts "=====>>>> FINISH import excel_price #{Time.now.to_s}"

    current_process = "=====>>>> FINISH import excel_price - #{Time.now.to_s} - Закончили импорт каталога товаров для файла клиента"
  	# ProductMailer.notifier_process(current_process).deliver_now
    FileUtils.rm_rf(Dir[Services::Import::DownloadPath+"/public/excel_price/*"]) if Rails.env.development?
  end

  def self.collect_main_list_cat_info(categories_main_list)
    account_url = "http://"+InsalesApi::Account.find.subdomain+".myinsales.ru"
    categories_main_list.each do |cat|
      search_cat = InsalesApi::Collection.find(cat[:id])
      cat[:link] = account_url+search_cat.url
      begin 
        cat[:image] = URI.encode(search_cat.image.original_url)
      rescue Exception => e
        puts "Error caught " + e.to_s
        next
      end
    end
    # puts "categories_main_list - "+categories_main_list.to_s
    categories_main_list
  end

  def self.download_remote_file(url)
    ascii_url = URI.encode(url)
    response = Net::HTTP.get_response(URI.parse(ascii_url))
    StringIO.new(response.body)
  end

  def self.collect_product_data_from_xml(pr, excel_price)
    picture_link = pr.css('picture').size > 1 ? pr.css('picture').first.text : pr.css('picture').text
    data = {
            id: pr['id'],
            title: pr.css('model').text.present? ? pr.css('model').text : ' ',
            sku: pr.css('vendorCode').text.present? ? pr.css('vendorCode').text : pr['id'],
            desc: pr.css('description').text.present? ? pr.css('description').text : ' ',
            price: Services::Import.price_shift(excel_price, pr.css('price').text),
            url: pr.css('url').text,
            image: Services::Import.process_image(picture_link, pr['id'])
          }
    data
  end
  
  def self.process_image(link, file_name)
    check = open(link)
    if check
    result = ImageProcessing::MiniMagick.source(link.gsub('https','http')).resize_and_pad(200, 200, background: "#FFFFFF", gravity: 'center').convert('jpg').call
    image_magic = MiniMagick::Image.open(result.path)
    image_magic.write(Services::Import::DownloadPath+"/public/excel_price/#{file_name}.jpg")
    image = File.expand_path(Services::Import::DownloadPath+"/public/excel_price/#{file_name}.jpg")
    else
      image = ''
    end
  end

  def self.price_shift(excel_price, price)
    filePrice = price.present? ? price.to_f : nil
    # puts filePrice.to_s
		price_move = excel_price.price_move
		price_shift = excel_price.price_shift
		price_points = excel_price.price_points
    
    if price_points == "fixed"
      new_price = price_move == "plus" ? (filePrice+price_shift.to_f).round(-1) : (filePrice-price_shift.to_f).round(-1)
    else
      new_price = price_move == "plus" ? (filePrice+price_shift.to_f*0.01*filePrice).round(-1) : (filePrice-price_shift.to_f*0.01*filePrice).round(-1)
    end
    # puts new_price.to_s
    new_price
  end

  def self.collect_product_ids(cat_id)
    pr_ids = InsalesApi::Collect.find(:all, :params => { collection_id: cat_id, limit: 1000 }).map(&:product_id)
  end

  def self.collect_our_product_ids(cat_id)
    all_offers = Nokogiri::XML(File.open(Services::Import::DownloadPath+"/public/1923917.xml")).xpath("//offer")
    pr_ids = InsalesApi::Collect.find(:all, :params => { collection_id: cat_id, limit: 1000 }).map(&:product_id)
    new_pr_ids = []
    pr_ids.each do |pr_id|
      pr = all_offers.select{ |offer| offer["id"] if offer.css('vendorCode').text.present? && 
                                                  offer["id"] == pr_id.to_s && offer.css('vendorCode').text.include?('ФД') ||
                                                  offer["id"] == pr_id.to_s && offer.css('vendorCode').text.include?('АДВ') ||
                                                  offer["id"] == pr_id.to_s && offer.css('vendorCode').text.include?('АДВСМ') ||
                                                  offer["id"] == pr_id.to_s && offer.css('vendorCode').text.include?('ФО') ||
                                                  offer["id"] == pr_id.to_s && offer.css('vendorCode').text.include?('УК')
                                                      }[0]
      new_pr_ids.push(pr['id']) if !pr.nil?
    end
    new_pr_ids
  end

  def self.load_all_catalog_xml
    input_path = "https://adventer.su/marketplace/1923917.xml"
    download_path = Services::Import::DownloadPath+"/public/1923917.xml"
    File.delete(download_path) if File.file?(download_path).present?

    RestClient.get( input_path ) { |response, request, result, &block|
      case response.code
      when 200
        f = File.new(download_path, "wb")
        f << response.body
        f.close
        puts "load_all_catalog_xml load and write"
      else
        response.return!(&block)
      end
      }
  end


end
