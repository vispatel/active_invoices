class AddVatNumberToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :vat_number, :string
  end
end
