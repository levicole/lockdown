#
# This is merely an extension of the Lockdown::Permissions module to
# allow for database manipulation of Permissions
#
# This is typically done via management screens.
#
class Permission < ActiveRecord::Base
  include Lockdown::Helper
  has_and_belongs_to_many :user_groups
  
  before_save :ensure_lockdown_permission_exists
  
	class << self
    include Lockdown::Helper
		#
    # Use this in your migrations to create a db record for management
    # functionality.  
    # 
    # Permission must be defined in:
    #		RAILS_ROOT/config/initializers/lockdown/access.rb
    #
		def create_record(sym)
      raise NameError.new("#{sym} is not defined.") unless Lockdown::Permissions.respond_to?(sym)
      create(:name => convert_reference_name(sym) )
		end

    #
    # Use this in your migrations to delete the permission identified by sym.
    #
    def delete_record(sym)
      privi = find_by_sym(sym)
      privi.destroy unless privi.nil?
    end

		    
    def find_by_sym(sym)
      if ENV['RAILS_ENV'] == "test"
        new(:name => convert_reference_name(sym))
      else
        find_by_name(convert_reference_name(sym))
      end
    end

    def all_but_public
      find(:all).delete_if do |perm| 
        Lockdown::UserGroups.public_access.include?(convert_reference_name(perm.name))
      end
    end
  end # end class block


	def access_rights
		sym = convert_reference_name(self.name) 
    Lockdown::Permissions[sym]
  end

	def all_users
		User.find_by_sql <<-SQL
			select users.* 
			from users, user_groups_users, permissions_user_groups
			where users.id = user_groups_users.user_id 
			and user_groups_users.user_group_id = permissions_user_groups.user_group_id
			and permissions_user_groups.permission_id = #{self.id}
		SQL
  end
  protected
	#
	# Cannot create a permission record in the db that is not defined
	# in config/initializers/lock_down_access
	#
	# Creating a db record is to simplify the creation of user groups
	# via management screens.
	#
	def ensure_lockdown_permission_exists
		unless Lockdown::Permissions.respond_to?(convert_reference_name(self.name))
			raise NameError.new("#{sym} is not defined.")
		end
	end
    
end
