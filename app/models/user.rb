class User < ApplicationRecord
  belongs_to :role
  has_many :orders
  # before_create :set_default_role
  # or
  before_validation :set_default_role
  has_one_attached :avatar, dependent: :destroy
  before_save :normalize_phone


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  def admin?
    role.name.include?('admin')
  end

  def manager?
    role.name.include?('manager')
  end

  def operator?
    role.name.include?('operator')
  end

  def bookkeeper?
    role.name.include?('bookkeeper')
  end

  def grand_manager?
    role.name.include?('grand_manager')
  end

  def can_show_all_order?
    admin? || operator? || bookkeeper? || grand_manager?
  end


  def avatar_thumbnail
    if avatar.attached?
      avatar.variant(combine_options: {auto_orient: true, thumbnail: '160x160', gravity: 'center', extent: '160x160' })
    else
      # "/default_avatar.png"
    end
  end

  private

  def normalize_phone
    self.phone = Phonelib.valid_for_country?(phone, 'RU') ? Phonelib.parse(phone).full_e164.presence : Phonelib.parse(phone, "KZ").full_e164.presence
  end

  def set_default_role
    self.role_id = Role.find_by_name('registered').id if role_id.nil?
  end

end
