class AddIndexToFamiliesArchivedInvestigator < ActiveRecord::Migration
  def change
  	add_index :activities, :activity_date
  	add_index :activities, :family_id
  	add_index :activities, :visit
  end
end
