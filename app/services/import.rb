class Services::Import

  def self.product
    require 'open-uri'
    puts '=====>>>> СТАРТ InSales EXCEL '+Time.now.to_s
    url = "https://adventer.su/marketplace/96164.xls"
		filename = url.split('/').last
    download = open(url)
		download_path = "#{Rails.public_path}"+"/"+filename
		IO.copy_stream(download, download_path)
    spreadsheet = Roo::Excel.new(download_path)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      sdesc = row["Краткое описание"].present? ? Product.strip_html(row["Краткое описание"]) : ''
      save_data = {
                  insvarid: row["ID варианта"].to_i,
                  sku: row["Артикул"].to_s,
                  title: row["Название товара"].to_s,
                  desc: sdesc,
                  price: row["Цена продажи"].to_i,
                  insid: row["ID товара"].to_i
                }

      search_product = Product.find_by_insvarid(save_data[:insvarid])
      product = search_product.present? ? search_product : Product.create!(save_data)
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
    excel_price.update!(file_status: false)
    url = excel_price.link
		filename = url.split('/').last
    download = open(url)
		download_path = "#{Rails.public_path}"+"/"+filename
		IO.copy_stream(download, download_path)
    data = Nokogiri::XML(open(download_path))
    offers = data.xpath("//offer")

    categories = data.xpath("//category").map{|c| {id: c["id"], title: c.text, parent_id: c["parentId"]}}
    # puts categories.to_s
    all_categories = Services::Import.collect_main_list_cat_info(categories)
    select_main_cat = all_categories.select{|c| c[:parent_id] == nil}
    # puts select_main_cat.to_s
    categories_for_list = all_categories.select{|c| c[:parent_id] == select_main_cat[0][:id]}

    p = Axlsx::Package.new
    wb = p.workbook
    
    s = wb.styles
    header = s.add_style bg_color: 'DD', sz: 16, b: true, alignment: { horizontal: :center, vertical: :center }
    header_second =  s.add_style bg_color: 'DD', sz: 14, b: true, alignment: { horizontal: :center, vertical: :center }
    tbl_header = s.add_style b: true, alignment: { horizontal: :center, vertical: :center  }
    ind_header = s.add_style bg_color: 'E4DBEF', sz: 16, b: true, alignment: { horizontal: :center, vertical: :center , indent: 1 }
    col_header = s.add_style bg_color: 'FFDFDEDF', b: true, alignment: { horizontal: :center , vertical: :center }
    label      = s.add_style alignment: { indent: 1 }
    money      = s.add_style alignment: { horizontal: :center , vertical: :center }, format_code: "# ##0\ ₽", border: Axlsx::STYLE_THIN_BORDER #num_fmt: 7
    main_label = s.add_style bg_color: 'F2F2F2', alignment: { horizontal: :center, vertical: :center, indent: 0, wrap_text: true }
    pr_title   = s.add_style alignment: { horizontal: :left , vertical: :center, indent: 1, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    pr_descr   = s.add_style alignment: { horizontal: :left , vertical: :center, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    pr_pict    = s.add_style border: Axlsx::STYLE_THIN_BORDER


    start_array_string = {0=>'B6',1=>'D6',2=>'F6',3=>'H6',4=>'B8',5=>'D8',6=>'F8',7=>'H8',8=>'B10',9=>'D10',10=>'F10',11=>'H10'}
    # end_array = {0=>'C7',1=>'E7',2=>'G7',3=>'I7',4=>'C9',5=>'E9',6=>'G9',7=>'I9',8=>'C11',9=>'E11',10=>'G11',11=>'I11'}
    start_array = {0=>[1,5],1=>[3,5],2=>[5,5],3=>[7,5],4=>[1,7],5=>[3,7],6=>[5,7],7=>[7,7],8=>[1,9],9=>[3,9],10=>[5,9],11=>[7,9]}
    end_array = {0=>[2,6],1=>[4,6],2=>[6,6],3=>[8,6],4=>[2,8],5=>[4,8],6=>[6,8],7=>[8,8],8=>[2,10],9=>[4,10],10=>[6,10],11=>[8,10]}
    wb.add_worksheet(name: 'Main') do |sheet|
      sheet.add_row [''], height: 30
      sheet.add_row [''], height: 30
      sheet.add_row [''], height: 30
      sheet.add_row ['Каталог продукции'], height: 50, style: header
      sheet.add_row [''], height: 10
      # categories_for_list.each_with_index do |cat, index|
      #   # puts "index - "+index.to_s
      #   # puts "start_array index - "+start_array[index].to_s
      #   image = Services::Import.load_convert_image(cat[:image])
      #   sheet.add_image(image_src: image, start_at: start_array[index].to_s, width: 200, height: 200, noResize: true, noMove: true, noRot: true)
      # end
      count_rows = (categories_for_list.count/4).ceil
      puts "count_rows - "+count_rows.to_s
      puts "start create main sheet rows"
      Array(0..count_rows).each do |arr|
        sheet.add_row ['','','','','','','',''], height: 150
        sheet.add_row ['','','','','','','',''], height: 40, style: [nil,main_label,nil,main_label,nil,main_label,nil,main_label]
      end
      puts "finish create main sheet rows"
      puts "start add collections to main sheet"
      categories_for_list.each_with_index do |cat, index|
          column_start = start_array[index][0]
          row_start = start_array[index][1]
          column_end = start_array[index][0]
          row_end = start_array[index][1]

          sheet.rows[row_end+1].cells[column_end].value = cat[:title]
          file_name = cat[:id]
          image = Services::Import.load_convert_image(cat[:image], file_name)
          # puts "image -"+image
          # puts "start_array[index].to_s - "+start_array[index].to_s
          # puts "end_array[index].to_s - "+end_array[index].to_s
          sheet.add_image(image_src: image, :noSelect => true, :noMove => true) do |image|
            image.width = 200
            image.height = 200
            image.start_at start_array_string[index]
            # image.start_at start_array[index][0], start_array[index][1]
            # image.end_at start_array[index][0], start_array[index][1]
          end
          sheet.add_hyperlink( location: "'#{cat[:title].at(0..30)}'!A1", target: :sheet, ref: sheet.rows[row_end+1].cells[column_end] )
      end
      puts "finish add collections to main sheet"

      sheet.column_widths 2,25,2,25,2,25,2,25,2
      sheet.merge_cells('A4:I4')
    end

    row_index_for_titles_array = []
    puts "start create seconds collections sheet"
    categories_for_list.each_with_index do |cat, index|
      puts "start create sheet - "+cat[:title]
        wb.add_worksheet(name: cat[:title].at(0..30)) do |sheet|
          sheet.add_row ["<= НА ГЛАВНУЮ",'', cat[:title]], style: [nil, nil, ind_header]
          second_cats = all_categories.select{ |c| c[:parent_id] == cat[:id] }
          if second_cats.present?
            second_cats.each do |s_cat|
              cat_title_row = sheet.add_row ['',s_cat[:title]], style: header_second, height: 30
              row_index_for_titles_array.push(cat_title_row.row_index+1)
              sheet.add_row ['','Название','Описание','Картинка','Цена'], style: tbl_header, height: 20
              cat_products = Rails.env.development? ? offers.select{|item| item.css('categoryId').text == s_cat[:id]}.take(1) : offers.select{|item| item.css('categoryId').text == s_cat[:id]}
              cat_products.each do |pr|
                price = Services::Import.price_shift(excel_price, pr.css('price').text)
                pr_row = sheet.add_row ['',pr.css('model').text, pr.css('description').text, '', price], style: [nil, pr_title, pr_descr, pr_pict, money]
                # puts "pr_row.row_index - "+pr_row.row_index.to_s
                hyp_ref = "B#{pr_row.row_index.to_s}"
                # puts hyp_ref.to_s
                sheet.add_hyperlink location: pr.css('url').text, ref: hyp_ref
                file_name = pr['id']
                picture = pr.css('picture').size > 1 ? pr.css('picture').first.text : pr.css('picture').text
                image = Services::Import.load_convert_image(picture, file_name)
                # puts "image -"+image
                # puts "start_array[index].to_s - "+start_array[index].to_s
                # puts "end_array[index].to_s - "+end_array[index].to_s
                sheet.add_image(image_src: image, :noSelect => true, :noMove => true) do |image|
                  image.width = 100
                  image.height = 100
                  image.start_at 3, pr_row.row_index
                  image.end_at 4, pr_row.row_index+1
                end            
              end
            end
          end
          if !second_cats.present?
            cat_title_row = sheet.add_row ['',cat[:title]], style: header_second, height: 30
            row_index_for_titles_array.push(cat_title_row.row_index+1)
            sheet.add_row ['','Название','Описание','Картинка','Цена'], style: tbl_header, height: 20
            cat_products = Rails.env.development? ? offers.select{|item| item.css('categoryId').text == cat[:id]}.take(5) : offers.select{|item| item.css('categoryId').text == cat[:id]}
            cat_products.each do |pr|
              price = Services::Import.price_shift(excel_price, pr.css('price').text)
              pr_row = sheet.add_row ['',pr.css('model').text, pr.css('description').text, '', price], style: [nil, pr_title, pr_descr, pr_pict, money]
              # puts "pr_row.row_index - "+pr_row.row_index.to_s
              hyp_ref = "B#{pr_row.row_index.to_s}"
              sheet.add_hyperlink location: pr.css('url').text, ref: hyp_ref
              file_name = pr['id']
              picture = pr.css('picture').size > 1 ? pr.css('picture').first.text : pr.css('picture').text
              image = Services::Import.load_convert_image(picture, file_name)
              # puts "image -"+image
              # puts "start_array[index].to_s - "+start_array[index].to_s
              # puts "end_array[index].to_s - "+end_array[index].to_s
              sheet.add_image(image_src: image, :noSelect => true, :noMove => true) do |image|
                image.width = 100
                image.height = 100
                image.start_at 3, pr_row.row_index
                image.end_at 4, pr_row.row_index+1
              end          
            end
          end

          sheet.merge_cells("A1:B1")
          sheet.merge_cells("C1:E1")
          sheet.add_hyperlink( location: "'Main'!A1", target: :sheet,ref: 'B1' )
          sheet.column_widths 2,40,40,40,20,2
          merge_ranges = row_index_for_titles_array.map{|a| "B"+a.to_s+":"+"E"+a.to_s }
          merge_ranges.uniq.each { |range| sheet.merge_cells(range) }
        end
      puts "finish create sheet - "+cat[:title]
    end
    puts "finish create seconds collections sheet"

    stream = p.to_stream
    file_path = "#{Rails.public_path}/#{excel_price.id.to_s}_file.xlsx"
    File.open(file_path, 'wb') { |f| f.write(stream.read) }

    excel_price.update!(file_status: true) if File.file?(file_path).present?
    File.delete(download_path) if File.file?(download_path).present?

    puts "=====>>>> FINISH import excel_price #{Time.now.to_s}"

    current_process = "=====>>>> FINISH import excel_price - #{Time.now.to_s} - Закончили импорт каталога товаров для файла клиента"
  	# ProductMailer.notifier_process(current_process).deliver_now
    FileUtils.rm_rf(Dir["#{Rails.public_path}/excel_price/*"])
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

  def self.load_convert_image(image_link, file_name)
    input_path = image_link.present? ? image_link : "http://157.245.114.19/kp_logo_footer.png"
    # puts "input_path - "+input_path.to_s
    # puts "file_name - "+file_name.to_s
    RestClient.get( input_path ) { |response, request, result, &block|
      case response.code
      when 200
        image_magic = MiniMagick::Image.open(input_path)
        convert_image = image_magic.format("jpeg")
        convert_image.write("#{Rails.public_path}/excel_price/#{file_name}.jpeg")
        image = File.expand_path("public/excel_price/#{file_name}.jpeg")
      when 400
        puts "image have 400 response"
        input_path = "http://157.245.114.19/kp_logo_footer.png"
        image_magic = MiniMagick::Image.open(input_path)
        convert_image = image_magic.format("jpeg")
        convert_image.write("#{Rails.public_path}/excel_price/#{file_name}.jpeg")
        image = File.expand_path("public/excel_price/#{file_name}.jpeg")    
      when 404
        puts "image have 404 response"
        input_path = "http://157.245.114.19/kp_logo_footer.png"
        image_magic = MiniMagick::Image.open(input_path)
        convert_image = image_magic.format("jpeg")
        convert_image.write("#{Rails.public_path}/excel_price/#{file_name}.jpeg")
        image = File.expand_path("public/excel_price/#{file_name}.jpeg")    
      else
        response.return!(&block)
      end
      }
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


end
