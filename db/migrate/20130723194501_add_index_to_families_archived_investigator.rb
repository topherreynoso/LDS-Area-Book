class AddIndexToFamiliesArchivedInvestigator < ActiveRecord::Migration
  def change
  	add_index :families, [:investigator, :archived], :name => 'by_ward_list', :where => {:investigator => false, :archived => false}
  	add_index :families, [:investigator, :archived], :name => 'by_investigator_list', :where => {:investigator => true, :archived => false}
  	add_index :families, [:investigator, :archived], :name => 'by_archived_ward_list', :where => {:investigator => false, :archived => true}
  	add_index :activities, :activity_date
  	add_index :activities, :family_id
  	add_index :activities, :visit
  end
end
