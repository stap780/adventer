class KpProduct < ApplicationRecord
  belongs_to :kp
  belongs_to :product

  validates :quantity, presence: true
  # validates :product_id, presence: true # убрал валидацию, так как мы создаём в форме КП сразу новые продукты
  validates :kp_id, presence: true

  delegate :title, to: :product, prefix: true, allow_nil: true # для автокомплита


end
