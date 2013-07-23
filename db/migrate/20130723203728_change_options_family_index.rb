class ChangeOptionsFamilyIndex < ActiveRecord::Migration
  def up
  	add_index :families, [:investigator, :archived], :name => "index_by_ward_list", :options => "WHERE investigator = false and archived = false"
  	add_index :families, [:investigator, :archived], :name => "index_by_investigator_list", :options => "WHERE investigator = true and archived = false"
  	add_index :families, [:investigator, :archived], :name => "index_by_archived_ward_list", :options => "WHERE investigator = false and archived = true"
  end

  def down
  	remove_index "families", :name => "by_ward_list"
  	remove_index "families", :name => "by_investigator_list"
  	remove_index "families", :name => "by_archived_ward_list"
  	remove_index "families", :name => "index_ward_list"
  	remove_index "families", :name => "index_investigator_list"
  	remove_index "families", :name => "index_archived_ward_list"
  end
end
