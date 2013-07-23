class AddWardIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :ward_id, :integer
  end
end
