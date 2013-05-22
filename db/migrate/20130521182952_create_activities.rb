class CreateActivities < ActiveRecord::Migration
  def change
    create_table :activities do |t|
      t.integer :family_id
      t.integer :user_id
      t.date :activity_date
      t.string :notes
      t.string :reported_by
      t.boolean :visit

      t.timestamps
    end
  end
end
