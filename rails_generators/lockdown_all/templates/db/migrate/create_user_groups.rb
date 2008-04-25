class CreateUserGroups < ActiveRecord::Migration
  def self.up
    create_table :user_groups do |t|
      t.string :name

      t.timestamps
    end
		create_join_table :user_groups, :users
  end

  def self.down
		drop_join_table :user_groups, :users
    drop_table :user_groups
  end
end
