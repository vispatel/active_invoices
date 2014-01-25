class RemoveTaxFromInvoices < ActiveRecord::Migration
  def change
    remove_column :invoices, :tax
  end
end
