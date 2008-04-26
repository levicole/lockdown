class CreateBaseUserGroups < ActiveRecord::Migration
  def self.up
	  UserGroup.create_record :administrators
	  UserGroup.create_record :public_access
	  UserGroup.create_record :registered_users
  end
	 
  def self.down
    #Nothing to see here...
	end
end
