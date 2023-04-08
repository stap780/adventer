class AddColumnUseDescToKpProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :kp_products, :use_desc, :boolean
  end
end
