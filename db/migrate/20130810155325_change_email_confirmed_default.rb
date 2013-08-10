class ChangeEmailConfirmedDefault < ActiveRecord::Migration
  def up
  	change_column :users, :email_confirmed, :boolean, :default => false
  end

  def down
  	change_column :users, :email_confirmed, :boolean, :default => true
  end
end
