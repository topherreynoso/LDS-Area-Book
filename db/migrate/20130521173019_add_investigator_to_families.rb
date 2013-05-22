class AddInvestigatorToFamilies < ActiveRecord::Migration
  def change
    add_column :families, :investigator, :boolean, default: false
  end
end
