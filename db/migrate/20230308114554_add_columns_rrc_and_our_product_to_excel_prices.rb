class AddColumnsRrcAndOurProductToExcelPrices < ActiveRecord::Migration[5.2]
  def change
    add_column :excel_prices, :rrc, :boolean
    add_column :excel_prices, :our_product, :boolean
  end
end
