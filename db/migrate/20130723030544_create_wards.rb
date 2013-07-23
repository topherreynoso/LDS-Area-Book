class CreateWards < ActiveRecord::Migration
  def change
    create_table :wards do |t|
      t.string :name
      t.string :unit

      t.timestamps
    end

    add_index :wards, :name
  end
end
