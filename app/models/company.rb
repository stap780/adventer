class Company < ApplicationRecord
  has_many :orders
  has_and_belongs_to_many :clients
  has_many_attached :images, dependent: :destroy
  validates :inn, presence: true
  validates :inn, uniqueness: true
  validates :title, presence: true

  scope :our, -> { where('our_company = ?', true).order(:id) }


  def inn_title
    "#{self.title} (ИНН: #{self.inn} )"
  end

end
