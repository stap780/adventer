class Order < ApplicationRecord
  belongs_to :client
  belongs_to :company
  belongs_to :companykp1, :class_name => 'Company', foreign_key: "companykp1_id"
	belongs_to :companykp2, :class_name => 'Company', foreign_key: "companykp2_id"
  belongs_to :companykp3, :class_name => 'Company', foreign_key: "companykp3_id"
  belongs_to :user
  has_many :kps, dependent: :destroy
  validates :number, presence: true, uniqueness: true
  validates :client_id, presence: true
  after_initialize :set_default_new
  before_validation :set_our_companies
  before_validation :check_manager_and_change_status
  # after_save :check_manager_and_send_notification
  after_commit :send_mail_to_operator , on: :create
  after_commit :check_manager_and_send_notification, if: :persisted?

  delegate :title, to: :company, prefix: true, allow_nil: true

  STATUS = ["Новый", "В работе", "Отменен"]

  def self.download_last_five
    puts "start download order"

    url_order = Insales::Api::Base_url+"orders.json?page=1&per_page=5"

    RestClient.get( url_order, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 200
        orders_data = JSON.parse(response)
        orders_data.each do |data|
          Order.one_order(data)
        end
      when 422
        puts "error 422 - не удалили товар"
      when 404
        puts 'error 404'
      when 503
        sleep 1
        puts 'sleep 1 error 503'
      else
        response.return!(&block)
      end
    end

    puts "end download order"
  end

  def self.download_one_order(insid)
    puts "start download order"

    url_order = Insales::Api::Base_url+"orders/"+insid.to_s+".json"

    RestClient.get( url_order, :accept => :json, :content_type => "application/json") do |response, request, result, &block|
      case response.code
      when 200
        data = JSON.parse(response)
        Order.one_order(data)
      when 422
        puts "error 422 - не удалили товар"
      when 404
        puts 'error 404'
      when 503
        sleep 1
        puts 'sleep 1 error 503'
      else
        response.return!(&block)
      end
    end

    puts "end download product"
  end

  def self.one_order(data)
    number = data["number"]
    insid = data["id"]
    order = Order.find_by_insid(insid)
    if !order.present?
      client = Client.api_get_create_client(data["client"])
      order = Order.create(number: number, insid: insid, client_id: client.id, status: Order::STATUS.first)
      kp = order.kps.create
      Order.create_kp_products(kp.id, data["order_lines"])
      puts "===> order not present and create <==="
    else
      # kp = order.kps.order(created_at: :asc).first
      client = Client.api_get_create_client(data["client"])
      order.update_attributes(client_id: client.id)
      kp = order.kps.create
      Order.create_kp_products(kp.id, data["order_lines"])
      puts "===> order present and crete new kp products <==="
    end
  end

  def self.create_kp_products(kp_id, order_lines)
    kp = Kp.find_by_id(kp_id)
    order_lines.each do |ol|
      data = {
        quantity: ol["quantity"],
        price: ol["sale_price"],
        sum: ol["total_price"],
        variant_id: ol["variant_id"],
        desc: ol["title"]
      }
      # pp data
      check_product = Product.find_by_insvarid(data[:variant_id])
      if check_product.present?
        data[:product_id] = check_product.id
      else
         Product.download_ins_product(ol["product_id"] )
         data[:product_id] = Product.find_by_insvarid(data[:variant_id]).id
      end
      data.delete(:variant_id)
      #kp.kp_products.create(quantity: data[:quantity], price:  data[:price], sum:  data[:sum], product_id:  product_id )
      kp.kp_products.create(data)
    end
  end

  private

  def set_our_companies
    if new_record?
      self.companykp1_id = Company.our.first.id
      self.companykp2_id = Company.our.second.present? ? Company.our.second.id : Company.our.first.id
      self.companykp3_id = Company.our.third.present? ? Company.our.third.id : Company.our.first.id
    end
  end

  def set_default_new
    if new_record? && !self.number.present?
      self.number = Order.last.id + 1
    end
    if new_record? && !self.created_at.present?
      self.created_at = Time.now
    end
    if new_record?
      self.status = Order::STATUS.first
    end
  end

  def check_manager_and_change_status
      self.status = "В работе" if user_id_changed?
  end

  def check_manager_and_send_notification
      OrderMailer.order_ready(self).deliver_now if saved_change_to_user_id?
  end

  def send_mail_to_operator
    OrderMailer.order_new(self).deliver_now
  end

end
