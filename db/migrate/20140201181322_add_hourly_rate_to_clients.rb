class AddHourlyRateToClients < ActiveRecord::Migration
  def change
    add_column :clients, :hourly_rate, :float
  end
end
