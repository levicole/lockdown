class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :name

      t.timestamps
    end
		create_join_table :permissions, :user_groups
  end

  def self.down
		drop_join_table :permissions, :user_groups
    drop_table :permissions
  end
end
