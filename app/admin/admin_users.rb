ActiveAdmin.register AdminUser do
  menu :label => "Users"

  filter :email
  filter :last_sign_in_at

  index do
    column :id
    column :company_name
    column :email
    column "Last Sign in", :last_sign_in_at
    default_actions
  end

  show :title => :email do
    attributes_table :company_name, :street_1, :street_2, :email, :last_sign_in_at, :created_at
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :admin
      f.input :company_name
      f.input :street_1
      f.input :street_2
      f.input :city
      f.input :state
      f.input :country, default: "United Kingdom"
      f.input :zip_code
      f.input :phone
      f.input :fax
      f.input :password, :type => :password
      f.input :password_confirmation, :type => :password
    end

    f.buttons
  end

end
