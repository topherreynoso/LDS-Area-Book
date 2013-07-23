class ChangeFamilyIndex < ActiveRecord::Migration
  def up
  	add_index :families, [:investigator, :archived], :name => 'index_ward_list', :where => [:investigator => false, :archived => false]
  	add_index :families, [:investigator, :archived], :name => 'index_investigator_list', :where => [:investigator => true, :archived => false]
  	add_index :families, [:investigator, :archived], :name => 'index_archived_ward_list', :where => [:investigator => false, :archived => true]
  end

  def down
  	remove_index :families, :name => 'by_ward_list'
  	remove_index :families, :name => 'by_investigator_list'
  	remove_index :families, :name => 'by_archived_ward_list'
  end
end
