class KpProduct < ApplicationRecord
  belongs_to :kp
  belongs_to :product
  default_scope { order(created_at: :asc) }
  before_save :normalize_data_white_space
  validates :quantity, presence: true
  # validates :product_id, presence: true # убрал валидацию, так как мы создаём в форме КП сразу новые продукты
  validates :kp_id, presence: true

  delegate :title, to: :product, prefix: true, allow_nil: true # для автокомплита

  private

  def normalize_data_white_space
	  self.attributes.each do |key, value|
	  	self[key] = value.squish if value.respond_to?("squish")
	  end
	end

end
