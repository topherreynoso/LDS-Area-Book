class AddNotesToFamilies < ActiveRecord::Migration
  def change
  	add_column :families, :notes, :string
  end
end
