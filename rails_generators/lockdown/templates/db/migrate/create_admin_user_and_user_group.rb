class CreateAdminUserAndUserGroup < ActiveRecord::Migration
  def self.up
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
