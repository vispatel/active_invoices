class AddServiceDescriptionToClients < ActiveRecord::Migration
  def change
    add_column :clients, :service_description, :string
  end
end
