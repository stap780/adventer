class KpProduct < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :kp
  belongs_to :product
  has_one_attached :image, dependent: :destroy
  accepts_nested_attributes_for :image_attachment, allow_destroy: true
  default_scope { order(created_at: :asc) }
  before_save :normalize_data_white_space
  validates :quantity, presence: true
  # validates :product_id, presence: true # убрал валидацию, так как мы создаём в форме КП сразу новые продукты
  validates :kp_id, presence: true

  attr_accessor :product_title
  delegate :title, :title=, to: :product, prefix: true, allow_nil: true # для автокомплита



  def image_thumbnail
    if image.attached?
      image.variant(combine_options: {auto_orient: true, thumbnail: '160x160', gravity: 'center', extent: '160x160' })
    else
      # "/default_avatar.png"
    end
  end
  
  def image_data
    return unless self.image.attached?
    image = self.image
    image.blob.attributes.slice('filename', 'byte_size', 'id').merge(url: image_url(image))
  end

  def image_url(image)
      rails_blob_path(image, only_path: true)
  end

  private

  def normalize_data_white_space
	  self.attributes.each do |key, value|
	  	self[key] = value.squish if value.respond_to?("squish")
	  end
	end

end
