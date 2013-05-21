class AddPasswordDigestToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :password_digest, :string
    add_index :users, :email, unique: true
  end
end
