class AddWatchedAndArchivedToFamilies < ActiveRecord::Migration
  def change
    add_column :families, :watched, :boolean, :default => false
    add_column :families, :archived, :boolean, :default => false
  end
end
