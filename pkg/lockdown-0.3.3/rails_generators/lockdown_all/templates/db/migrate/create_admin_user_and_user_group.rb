class CreateAdminUserAndUserGroup < ActiveRecord::Migration
  def self.up
		#
		# Creating an administrators user group database record
    # to allow for the creation of other administrators
		#
		Lockdown::System.create_administrator_user_group

		# TODO: Change the password
    u = User.new(	:password => "password", 
									:password_confirmation => "password", 
									:login => "admin")

    u.profile = Profile.create(:first_name => "Administrator",
																:last_name => "User",
																:email => "administrator@a.com")
    u.save

		Lockdown::System.make_user_administrator(u)
  end
	 
  def self.down
    #Nothing to see here...
	end
end
