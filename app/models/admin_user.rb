class AdminUser < ActiveRecord::Base
  has_many :clients
  has_many :organizations
  has_many :invoices

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :admin, :company_name, :company_address, :street_1, :street_2, :city, :state, :country, :zip_code, :phone, :fax, :intervals_token, :intervals_secret, :intervals_person_id
end
