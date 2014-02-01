class Organization < ActiveRecord::Base
  has_many :clients, :dependent => :destroy
  belongs_to :admin_user

  validates :name, :presence => true

  attr_accessible :business_phone, :city, :country, :fax, :name, :state, :street_1, :street_2, :zip_code, :clients_attributes, :vat_number, :sort_code, :account_number, :bank_name

  accepts_nested_attributes_for :clients, :allow_destroy => true
end
