class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login
      t.string :crypted_password
      t.string :salt
      t.integer :updated_by

      t.timestamps
    end
    add_foreign_key :users, :profiles
    define_foreign_key_column :users, :updated_by, :profiles
  end

  def self.down
    remove_foreign_key :users, :profiles
    remove_foreign_key_column :users, :updated_by
    drop_table :users
  end
end
