class AddDefaultToVisitAttribute < ActiveRecord::Migration
  def up
  	change_column :activities, :visit, :boolean, :default => true
  end

  def down
  	change_column :activities, :visit, :boolean, :default => nil
  end
end
