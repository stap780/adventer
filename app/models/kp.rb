class Kp < ApplicationRecord
  belongs_to :order

  has_many :kp_products, dependent: :destroy
  accepts_nested_attributes_for :kp_products, reject_if: :all_blank, allow_destroy: true
  has_many :products, :through => :kp_products

  validates :order_id, presence: true
  after_initialize :set_status_vid
  after_initialize :set_title
  before_validation :check_status_if_manager_set_print_ready
  after_commit :notify_bookkeeper_to_add_stamp, if: :persisted?
  after_commit :notify_manager_kp_ready, if: :persisted?

  VID = ["Начальное","В работе","Основное"]
  STATUS = ["Новый","В работе","Финальный"]#["Новый","В работе","Ждёт печати","Согласовано бухгалтером","Договор"]

  def self.import(file, order, kp)
		puts 'импорт файла '+Time.now.to_s
    kp = Kp.find_by_id(kp)
		spreadsheet = open_spreadsheet(file)
		header = spreadsheet.row(1)
		(2..spreadsheet.last_row).each do |i|
			row = Hash[[header, spreadsheet.row(i)].transpose]
      sku = row["sku"]
      title = row["title"]
      pr_quantity = row["quantity"]
      price = row["price"]
      product = Product.find_by_title(title)
      product_id = product.present? ? product.id : Product.create(sku: sku, title: title, quantity: 1, price: price).id

      kp_product_data = { product_id: product_id, quantity: pr_quantity, price: price }

      k_p = kp.kp_products.where(product_id: product_id).take
			k_p.present? ? k_p.update_attributes(quantity: pr_quantity+k_p.quantity) : kp.kp_products.create(kp_product_data)

		end
		puts 'конец импорт файл '+Time.now.to_s
	end

  def self.open_spreadsheet(file)
	    case File.extname(file.original_filename)
	    when ".csv" then Roo::CSV.new(file.path)#csv_options: {col_sep: ";",encoding: "windows-1251:utf-8"})
	    when ".xls" then Roo::Excel.new(file.path)
	    when ".xlsx" then Roo::Excelx.new(file.path)
	    when ".XLS" then Roo::Excel.new(file.path)
	    else raise "Unknown file type: #{file.original_filename}"
	    end
	end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |item|
        csv << item.attributes.values_at(*column_names)
      end
    end
  end

  private

  def set_status_vid
    self.status = Kp::STATUS.first if new_record?
    self.vid = Kp::VID.first if new_record?
  end

  def set_title
    if !self.order.present?
      self.title = "Коммерческое предложение "+self.order_id.to_s if new_record?
    else
      self.title = "Коммерческое предложение "+self.order_id.to_s+"/"+self.order.kps.count.to_s if new_record?
    end
  end

  def check_status_if_manager_set_print_ready
      self.vid = 'Основное' if self.status == 'Ждёт печати'
  end

  def notify_bookkeeper_to_add_stamp
      KpMailer.add_stamp(self).deliver_now if self.status == 'Ждёт печати' && self.vid == 'Основное'
  end

  def notify_manager_kp_ready
      KpMailer.kp_ready(self).deliver_now if self.status == 'Согласовано бухгалтером' && self.vid == 'Основное'
  end


end
