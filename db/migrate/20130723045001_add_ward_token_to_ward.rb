class AddWardTokenToWard < ActiveRecord::Migration
  def change
    add_column :wards, :ward_token, :string
    add_index  :wards, :ward_token
  end
end
