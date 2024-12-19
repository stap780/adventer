class AddOurToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :our, :boolean, default: false
  end
end
