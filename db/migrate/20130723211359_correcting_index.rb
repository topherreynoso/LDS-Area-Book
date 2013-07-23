class CorrectingIndex < ActiveRecord::Migration
  def change
  	add_index :families, [:investigator, :archived], name: "ward_list", where: "investigator = false and archived = false"
  	add_index :families, [:investigator, :archived], name: "investigator_list", where: "investigator = true and archived = false"
  	add_index :families, [:investigator, :archived], name: "archived_ward_list", where: "investigator = false and archived = true"
  end
end