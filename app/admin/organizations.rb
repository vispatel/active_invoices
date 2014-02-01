ActiveAdmin.register Organization do
  index do
    column :name
    column :business_phone
    default_actions
  end

  filter :name

  form do |f|
    f.inputs "Organization" do
      f.input :name
      f.input :street_1
      f.input :street_2
      f.input :city
      f.input :state
      f.input :country
      f.input :zip_code
      f.input :business_phone
      f.input :fax
      f.input :vat_number
    end
    f.inputs "Bank details" do
      f.input :bank_name
      f.input :sort_code
      f.input :account_number
    end

    f.buttons
  end

end
