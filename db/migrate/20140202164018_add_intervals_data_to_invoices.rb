class AddIntervalsDataToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :intervals_data, :text
  end
end
