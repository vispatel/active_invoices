class AddCompanyRegistrationNumberToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :company_registration_number, :string
  end
end
