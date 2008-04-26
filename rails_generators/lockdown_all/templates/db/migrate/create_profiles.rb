class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.integer :updated_by
      t.boolean :is_disabled

      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
