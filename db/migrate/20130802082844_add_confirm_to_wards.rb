class AddConfirmToWards < ActiveRecord::Migration
  def change
  	add_column :wards, :confirm, :string
  end
end
