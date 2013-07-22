class AddIndexesToFamilies < ActiveRecord::Migration
  def change
    add_index :families, :archived
    add_index :families, :investigator
  end
end
