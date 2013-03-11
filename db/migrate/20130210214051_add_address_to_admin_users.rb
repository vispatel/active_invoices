class AddAddressToAdminUsers < ActiveRecord::Migration
  def change
    add_column :admin_users, :company_name, :string
    add_column :admin_users, :street_1, :string
    add_column :admin_users, :street_2, :string
    add_column :admin_users, :city, :string
    add_column :admin_users, :state, :string
    add_column :admin_users, :country, :string
    add_column :admin_users, :zip_code, :string
    add_column :admin_users, :phone, :string
    add_column :admin_users, :fax, :string
  end
end
