class AddColumnsTextDostavkaTextSborkaToKps < ActiveRecord::Migration[5.2]
  def change
    add_column :kps, :text_dostavka, :string
    add_column :kps, :text_sborka, :string
  end
end
