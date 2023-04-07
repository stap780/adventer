class AddColumnNumberAdventerToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :number_adventer, :string
  end
end
