class AddAuthCodeToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :auth_code, :string
  end
end
