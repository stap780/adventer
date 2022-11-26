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
    File.delete("#{Rails.public_path}/#{excel_price.id.to_s}_file.xlsx") if File.file?("#{Rails.public_path}/#{excel_price.id.to_s}_file.xlsx").present?
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
    header = s.add_style sz: 16, b: true, alignment: { horizontal: :center, vertical: :center } #bg_color: 'DD',
    header_second =  s.add_style bg_color: 'E6F1F1', sz: 14, b: true, alignment: { horizontal: :center, vertical: :center }
    tbl_header = s.add_style b: true, alignment: { horizontal: :center, vertical: :center  }
    ind_header = s.add_style bg_color: 'CDE3E3', sz: 16, b: true, alignment: { horizontal: :center, vertical: :center , indent: 1 }
    col_header = s.add_style bg_color: 'FFDFDEDF', b: true, alignment: { horizontal: :center , vertical: :center }
    label      = s.add_style alignment: { indent: 1 }
    money      = s.add_style alignment: { horizontal: :center , vertical: :center }, format_code: "# ##0\ ₽", border: Axlsx::STYLE_THIN_BORDER, b: true
    main_label = s.add_style bg_color: 'E6F1F1', alignment: { horizontal: :center, vertical: :center, indent: 0, wrap_text: true }, b: true
    pr_title   = s.add_style alignment: { horizontal: :left , vertical: :center, indent: 1, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER, b: true
    pr_sku   = s.add_style alignment: { horizontal: :left , vertical: :center, indent: 1, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    pr_descr   = s.add_style alignment: { horizontal: :left , vertical: :center, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER, sz: 10
    pr_pict    = s.add_style alignment: { horizontal: :center , vertical: :center },border: Axlsx::STYLE_THIN_BORDER
    pr_index   = s.add_style alignment: { horizontal: :center , vertical: :center, wrap_text: true }, border: Axlsx::STYLE_THIN_BORDER
    back_button = s.add_style alignment: { horizontal: :center , vertical: :center, wrap_text: true }, bg_color: 'B4D5D5', sz: 14
    bg_w = s.add_style bg_color: 'FFFFFF'
    but_rekv = s.add_style bg_color: 'FFFFFF', alignment: { horizontal: :left , vertical: :top, indent: 1, wrap_text: true }, fg_color: '7F7F7F'
    notice_main_label = s.add_style bg_color: 'FFFFFF', alignment: { horizontal: :center , vertical: :top }
    notice_label = s.add_style bg_color: 'FDE9D9', alignment: { horizontal: :center , vertical: :center}, b: true, sz: 12
    notice_b = s.add_style bg_color: 'FDE9D9', alignment: { horizontal: :center , vertical: :center }, sz: 12


    start_array_string = {0=>'B6',1=>'D6',2=>'F6',3=>'H6',4=>'B8',5=>'D8',6=>'F8',7=>'H8',8=>'B10',9=>'D10',10=>'F10',11=>'H10'}
    # end_array = {0=>'C7',1=>'E7',2=>'G7',3=>'I7',4=>'C9',5=>'E9',6=>'G9',7=>'I9',8=>'C11',9=>'E11',10=>'G11',11=>'I11'}
    start_array = {0=>[1,5],1=>[3,5],2=>[5,5],3=>[7,5],4=>[1,7],5=>[3,7],6=>[5,7],7=>[7,7],8=>[1,9],9=>[3,9],10=>[5,9],11=>[7,9]}
    end_array = {0=>[2,6],1=>[4,6],2=>[6,6],3=>[8,6],4=>[2,8],5=>[4,8],6=>[6,8],7=>[8,8],8=>[2,10],9=>[4,10],10=>[6,10],11=>[8,10]}
    notice_text_main_sheet = Axlsx::RichText.new
    notice_text_main_sheet.add_run('Подсказка: ', b: true, color: 'EA4488')
    notice_text_main_sheet.add_run('для того чтобы открыть нужную категорию нажмите на название или вкладку')
  
    wb.add_worksheet(name: 'Навигация по каталогу') do |sheet|
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','','','','','','','','','',''], height: 30, style: bg_w
      sheet.add_row ['','Каталог продукции','','','','','','','','Реквизиты',''], height: 50, style: [bg_w,header,bg_w,bg_w,bg_w,bg_w,bg_w,bg_w,bg_w,header,bg_w]
      sheet.add_row ['',notice_text_main_sheet,'','','','','','','','',''], height: 20, style: notice_main_label

      count_rows = (categories_for_list.count/4).ceil
      puts "count_rows - "+count_rows.to_s
      puts "start create main sheet rows"
      Array(0..count_rows).each do |arr|
        sheet.add_row ['','','','','','','','','','',''], height: 150, style: bg_w
        sheet.add_row ['','','','','','','','','','',''], height: 40, style: [bg_w,nil,bg_w,nil,bg_w,nil,bg_w,nil,bg_w,bg_w,bg_w]
      end
      sheet.add_row ['','','','','','','','','','',''], height: 80, style: bg_w
      puts "finish create main sheet rows"
      puts "start add collections to main sheet"
      categories_for_list.each_with_index do |cat, index|
          column_start = start_array[index][0]
          row_start = start_array[index][1]
          column_end = start_array[index][0]
          row_end = start_array[index][1]

          sheet.rows[row_end+1].cells[column_end].value = cat[:title]
          sheet.rows[row_end+1].cells[column_end].style = main_label


          url = cat[:image]
          temp_filename = "temp_"+cat[:id].to_s+"."+url.split('.').last
          download = open(url)
          download_path = "#{Rails.public_path}/excel_price/"+temp_filename
          IO.copy_stream(download, download_path)
          new_image_link = Rails.env.development? ? "http://localhost:3000/excel_price/"+temp_filename : "http://157.245.114.19/excel_price/"+temp_filename
          puts new_image_link
          file_name = cat[:id]
          # image = Services::Import.load_convert_image(cat[:image], file_name)
          image = Services::Import.load_convert_image(new_image_link, file_name)
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

      sheet.column_widths 2,25,2,25,2,25,2,25,10,50,10
      sheet.merge_cells('B4:H4')
      sheet.merge_cells('B5:H5')
      sheet.merge_cells('J6:J11')
      logo_image = Services::Import.load_convert_image('http://157.245.114.19/adventer_logo_excel.jpg', 'logo')
      sheet.add_image(image_src: logo_image, start_at: 'A1', end_at: 'L4')
      sheet['J6'].value = 'Общество с ограниченной ответственностью «Адвентер»

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
      sheet['J6'].style = but_rekv
      puts "finish add collections to main sheet"
    end

    row_index_for_titles_array = []
    puts "start create seconds collections sheet"
    categories_for_list.each_with_index do |cat, index|
      puts "start create sheet - "+cat[:title]
      notice_text = Axlsx::RichText.new
      notice_text.add_run('Подсказка: ', :b => true)
      notice_text.add_run('для того чтобы открыть позицию на сайте нажмите на наименование/фото товара')
        wb.add_worksheet(name: cat[:title].at(0..30)) do |sheet|
          sheet.add_row ['','<= НА ГЛАВНУЮ','', cat[:title]], style: [nil,back_button,back_button,ind_header], height: 30
          sheet.add_row ['',notice_text,'','','','',''], style: [nil,notice_b,notice_label,notice_b,notice_b,notice_b,notice_b,notice_b], height: 20
          second_cats = all_categories.select{ |c| c[:parent_id] == cat[:id] }
          if second_cats.present?
            second_cats.each do |s_cat|
              cat_title_row = sheet.add_row ['',s_cat[:title]], style: [nil,header_second], height: 30
              row_index_for_titles_array.push(cat_title_row.row_index+1)
              sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена'], style: tbl_header, height: 20
              cat_products = Rails.env.development? ? offers.select{|item| item.css('categoryId').text == s_cat[:id]}.take(2) : offers.select{|item| item.css('categoryId').text == s_cat[:id]}
              cat_products.each_with_index do |pr, index|
                title = pr.css('model').text.present? ? pr.css('model').text : ' '
                sku = pr.css('sku').text.present? ? pr.css('sku').text : pr['id']
                desc = pr.css('description').text.present? ? pr.css('description').text : ' '
                price = Services::Import.price_shift(excel_price, pr.css('price').text)
                pr_data = ['',(index+1).to_s,'',title,sku,desc,price]
                #puts pr_data.to_s if pr['id'] == '139020547'
                pr_row = sheet.add_row pr_data, style: [nil,pr_index,pr_pict,pr_title,pr_sku,pr_descr,money], height: 150
                # puts "pr_row.row_index - "+pr_row.row_index.to_s
                hyp_ref = "D#{(pr_row.row_index+1).to_s}"
                # puts hyp_ref.to_s
                sheet.add_hyperlink location: pr.css('url').text, ref: hyp_ref
                file_name = pr['id']
                picture_link = pr.css('picture').size > 1 ? pr.css('picture').first.text : pr.css('picture').text
                image = Services::Import.load_convert_image(picture_link, file_name)
                # image_width = MiniMagick::Image.open(image)[:width].to_i
                # image_height = MiniMagick::Image.open(image)[:height].to_i
                # puts "image -"+image
                # puts "start_array[index].to_s - "+start_array[index].to_s
                # puts "end_array[index].to_s - "+end_array[index].to_s
                sheet.add_image(image_src: image, :noSelect => true, :noMove => true, hyperlink: pr.css('url').text) do |image|
                  # image.width = image_width-5
                  # image.height = image_height-5
                  image.start_at 2, pr_row.row_index
                  image.end_at 3, pr_row.row_index+1
                  image.anchor.from.rowOff = 10_000
                  image.anchor.from.colOff = 10_000
                end            
              end
            end
          end
          if !second_cats.present?
            cat_title_row = sheet.add_row ['',cat[:title]], style: [nil,header_second], height: 30
            row_index_for_titles_array.push(cat_title_row.row_index+1)
            sheet.add_row ['','№','Фото','Наименование','Артикул','Описание','Цена'], style: tbl_header, height: 20
            cat_products = Rails.env.development? ? offers.select{|item| item.css('categoryId').text == cat[:id]}.take(2) : offers.select{|item| item.css('categoryId').text == cat[:id]}
            cat_products.each_with_index do |pr, index|
              title = pr.css('model').text.present? ? pr.css('model').text : ' '
              sku = pr.css('sku').text.present? ? pr.css('sku').text : pr['id']
              desc = pr.css('description').text.present? ? pr.css('description').text : ' '
              price = Services::Import.price_shift(excel_price, pr.css('price').text)
              pr_data = ['',(index+1).to_s,'',title,sku,desc,price]
              #puts pr_data.to_s if pr['id'] == '139020547'
              pr_row = sheet.add_row pr_data, style: [nil,pr_index,pr_pict,pr_title,pr_sku,pr_descr,money], height: 110
              # puts "pr_row.row_index - "+pr_row.row_index.to_s
              hyp_ref = "D#{(pr_row.row_index+1).to_s}"
              sheet.add_hyperlink location: pr.css('url').text, ref: hyp_ref
              file_name = pr['id']
              picture = pr.css('picture').size > 1 ? pr.css('picture').first.text : pr.css('picture').text
              image = Services::Import.load_convert_image(picture, file_name)
              # puts "image -"+image
              # puts "start_array[index].to_s - "+start_array[index].to_s
              # puts "end_array[index].to_s - "+end_array[index].to_s
              sheet.add_image(image_src: image, :noSelect => true, :noMove => true) do |image|
                # image.width = 100
                image.height = 90
                image.start_at 2, pr_row.row_index
                image.end_at 3, pr_row.row_index+1
              end          
            end
          end

          sheet.merge_cells("B1:C1")
          sheet.merge_cells("D1:G1")
          sheet.merge_cells("B2:G2")
          sheet.add_hyperlink( location: "'Навигация по каталогу'!A7", target: :sheet, ref: 'B1' )
          sheet.column_widths 2,10,25,40,40,40,40,2
          merge_ranges = row_index_for_titles_array.map{|a| "B"+a.to_s+":"+"G"+a.to_s }
          merge_ranges.uniq.each { |range| sheet.merge_cells(range) }
          sheet.sheet_view.pane do |pane|
            # pane.top_left_cell = 'A2'
            # pane.state = :frozen_split
            # pane.y_split = 1
            # pane.x_split = 1
            # pane.active_pane = :bottom_right
            pane.state = :frozen
            pane.x_split = 1
            pane.y_split = 2
          end
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
        image_process = ImageProcessing::MiniMagick.source(input_path)
        result = file_name == "logo" ? input_path : image_process.resize_and_pad!(200, 200).path
        image_magic = MiniMagick::Image.open(result)
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

  # def self.resize_with_nocrop(image, w, h)

  #   w_original = image[:width].to_f
  #   h_original = image[:height].to_f

  #   if (w_original*h != h_original * w)
  #     if w_original*h >= h_original * w
  #       # long width
  #       w_result = w
  #       h_result = w_result * (h_original / w_original)
  #     elsif w_original*h <= h_original * w
  #       # long height
  #       h_result = h
  #       w_result = h_result * (w_original / h_original)
  #     end
  #   else
  #      # good proportions
  #      h_result = h
  #      w_result = w
  #   end

  #   #
  #   image.resize("#{w_result}x#{h_result}")
  #   return image
  # end

  # def resize_nocrop_noscale(image, w,h)
  #   w_original = image[:width].to_f
  #   h_original = image[:height].to_f

  #   if w_original < w && h_original < h
  #     return image
  #   end

  #   # resize
  #   image.resize("#{w}x#{h}")

  #   return image
  # end

  # def resize_with_crop(img, w, h, options = {})
  #   gravity = options[:gravity] || :center

  #   w_original, h_original = [img[:width].to_f, img[:height].to_f]

  #   op_resize = ''

  #   # check proportions
  #   if w_original * h < h_original * w
  #     op_resize = "#{w.to_i}x"
  #     w_result = w
  #     h_result = (h_original * w / w_original)
  #   else
  #     op_resize = "x#{h.to_i}"
  #     w_result = (w_original * h / h_original)
  #     h_result = h
  #   end

  #   w_offset, h_offset = crop_offsets_by_gravity(gravity, [w_result, h_result], [ w, h])

  #   img.combine_options do |i|
  #     i.resize(op_resize)
  #     i.gravity(gravity)
  #     i.crop "#{w.to_i}x#{h.to_i}+#{w_offset}+#{h_offset}!"
  #   end

  #   img
  # end

  # # from http://www.dweebd.com/ruby/resizing-and-cropping-images-to-fixed-dimensions/

  # GRAVITY_TYPES = [ :north_west, :north, :north_east, :east, :south_east, :south, :south_west, :west, :center ]

  # def crop_offsets_by_gravity(gravity, original_dimensions, cropped_dimensions)
  #   raise(ArgumentError, "Gravity must be one of #{GRAVITY_TYPES.inspect}") unless GRAVITY_TYPES.include?(gravity.to_sym)
  #   raise(ArgumentError, "Original dimensions must be supplied as a [ width, height ] array") unless original_dimensions.kind_of?(Enumerable) && original_dimensions.size == 2
  #   raise(ArgumentError, "Cropped dimensions must be supplied as a [ width, height ] array") unless cropped_dimensions.kind_of?(Enumerable) && cropped_dimensions.size == 2

  #   original_width, original_height = original_dimensions
  #   cropped_width, cropped_height = cropped_dimensions

  #   vertical_offset = case gravity
  #     when :north_west, :north, :north_east then 0
  #     when :center, :east, :west then [ ((original_height - cropped_height) / 2.0).to_i, 0 ].max
  #     when :south_west, :south, :south_east then (original_height - cropped_height).to_i
  #   end

  #   horizontal_offset = case gravity
  #     when :north_west, :west, :south_west then 0
  #     when :center, :north, :south then [ ((original_width - cropped_width) / 2.0).to_i, 0 ].max
  #     when :north_east, :east, :south_east then (original_width - cropped_width).to_i
  #   end

  #   return [ horizontal_offset, vertical_offset ]
  # end

end
