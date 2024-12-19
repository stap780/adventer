class Product < ApplicationRecord

  has_many :kp_products, dependent: :destroy
  has_many :kps, :through => :kp_products
  has_many_attached :images, dependent: :destroy
  accepts_nested_attributes_for :images_attachments, allow_destroy: true
  before_save :normalize_data_white_space
  validates :title, presence: true
  # validates :sku, presence: true, uniqueness: true
  validates :images, size: { less_than: 15.megabytes , message: 'размер файла должен быть меньше 15Мб' }
  scope :search_by_title_sku, ->(q) { where("title ILIKE ? or sku ILIKE ?", "%#{q}%", "%#{q}%").order(:title) }


  def autocomplete_title
    # такая запись ниже, так как этот результат подсовывается в json автокомплита и только так там срабатывают html теги
    autocomplete_title = self.sku.present? ? self.title+"<br><small style='color:grey;'>Артикул: "+self.sku : self.title+"<br><small style='color:grey;'>Артикул:  Не указан"
    autocomplete_title.html_safe
  end

  def self.download_ins_product(insid)
    url_product = Insales::Api::Base_url+"products/"+insid.to_s+".json"
    RestClient.get( url_product, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 200
        data = JSON.parse(response)
        data["variants"].each do |var|
          sdesc = data["short_description"].present? ? Product.strip_html(data["short_description"]) : nil
          fdesc = data["description"].present? ? Product.strip_html(data["description"]) : ''
          desc = sdesc.present? ? sdesc : fdesc
          save_data = {
            insvarid: var["id"],
            title: data["title"],
            desc: desc,
            insid: data["id"],
            sku: var["sku"],
            quantity: var["quantity"],
            costprice: var["cost_price"],
            price: var["price"]
          }
          search_product = Product.find_by_insvarid(save_data[:insvarid])
          product = search_product.present? ? search_product : Product.create!(save_data)

          #pp save_data

          puts "product - #{product.id}"
          data['images'].take(1).each do |i|
            url = i["large_url"]
            img_filename = i["filename"]
            if product.images.size < 3 && !product.images.select{|im| im.filename.to_s == img_filename }.present?
              file = Product.download_remote_file(url)
              product.images.attach(io: file, filename: img_filename, content_type: "image/jpg")
            end
          end
        end
      when 422
        puts "error 422 - "
      when 404
        puts 'error 404'
      when 503
        sleep 1
        puts 'sleep 1 error 503'
      else
        response.return!(&block)
      end
    end

  end

  def self.download_remote_file(url)
    ascii_url = URI.encode(url)
    response = Net::HTTP.get_response(URI.parse(ascii_url))
    StringIO.new(response.body)
  end

  def self.strip_html(content_data)
    content = Nokogiri::HTML(content_data)
    content.text.squish if content.text.respond_to?("squish")
  end

  def ins_ids_info
    return '' unless insid.present? || insvarid.present?

    "<small>id товара: #{insid}<br>id варианта: #{insvarid}</small>".html_safe
  end


  private

  def normalize_data_white_space
	  self.attributes.each do |key, value|
	  	self[key] = value.squish if value.respond_to?("squish")
	  end
	end

  # def self.image_center_thumb_url(image)
  #   variant = image.variant(combine_options: {auto_orient: true, thumbnail: '40x40', gravity: 'center', extent: '40x40' }).processed
  #   Rails.application.routes.url_helpers.rails_representation_url(variant, only_path: true)
  # end


end
