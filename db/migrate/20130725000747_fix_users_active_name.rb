class FixUsersActiveName < ActiveRecord::Migration
  def change
  	rename_column :users, :active, :email_confirmed
  end
end
