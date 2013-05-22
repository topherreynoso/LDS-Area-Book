class ChangeDefaultToVisitAttribute < ActiveRecord::Migration
  def up
  	change_column :activities, :visit, :boolean, :default => false
  end

  def down
  	change_column :activities, :visit, :boolean, :default => true
  end
end
