class AddBankDetailsToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :bank_name, :string
    add_column :organizations, :sort_code, :string
    add_column :organizations, :account_number, :string
  end
end