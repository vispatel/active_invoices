class AddIntervalsApiFieldsToAdminUsers < ActiveRecord::Migration
  def change
    add_column :admin_users, :intervals_token, :string
    add_column :admin_users, :intervals_secret, :string
    add_column :admin_users, :intervals_person_id, :string
  end
end
