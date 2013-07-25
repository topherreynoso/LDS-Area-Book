class AddWardConfirmedToUser < ActiveRecord::Migration
  def change
    add_column :users, :ward_confirmed, :boolean, :default => false
    add_index :users, :ward_confirmed
  end
end
