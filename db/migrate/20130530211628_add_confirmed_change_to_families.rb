class AddConfirmedChangeToFamilies < ActiveRecord::Migration
  def change
    add_column :families, :confirmed_change, :boolean, :default => false
  end
end
