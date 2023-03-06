class ChangeColumnTypeFileStatusToExcelPrices < ActiveRecord::Migration[5.2]
  def change
    change_column :excel_prices, :file_status, :string
  end
end
