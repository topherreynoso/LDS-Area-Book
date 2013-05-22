class CreateFamilies < ActiveRecord::Migration
  def change
    create_table :families do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.string :address
      t.string :children

      t.timestamps
    end
    
    add_index :families, :name
  end
end
