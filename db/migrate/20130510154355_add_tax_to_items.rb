class AddTaxToItems < ActiveRecord::Migration
  def change
    add_column :items, :tax, :float
  end
end
