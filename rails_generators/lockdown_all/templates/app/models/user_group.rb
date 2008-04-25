class UserGroup < ActiveRecord::Base
  include Lockdown::Helper
  has_and_belongs_to_many :permissions
  has_and_belongs_to_many :users

  validates_presence_of :name
	
	before_update :protect_private
	before_destroy :protect_private_and_protected
  
  class << self
    include Lockdown::Helper
    #
    # Pull from the Lockdown::UserGroups module if defined.
    # Otherwise. load from db.
    #
    def [](sym)
	    return Lockdown::UserGroups[sym] if Lockdown::UserGroups.respond_to? sym
      ug = UserGroup.find_by_name(convert_reference_name(sym))
			ug.access_rights
    end
    
    def find_by_sym(sym)
      if ENV['RAILS_ENV'] == "test"
        new(:name => convert_reference_name(sym))
      else
        find_by_name(convert_reference_name(sym))
      end
    end

		def find_by_name(str)
			find :first, :conditions => ["name = ?",str] 
    end
    
		#
    # Use this in your migrations to create a db record for management
    # functionality.  
    #
    def create_record(sym)
      raise NameError.new("#{sym} is not defined.") unless Lockdown::UserGroups.respond_to?(sym)
      ug = create(:name => convert_reference_name(sym))
      unless Lockdown::UserGroups.private_records.include?(sym)
        Lockdown::UserGroups.permissions(sym).each do |perm|
          ug.permissions << Permission.find_or_create_by_name(convert_reference_name(perm))
        end
      end
    end

    #
    # Use this in your migrations to add permissions to a user group 
    # identified by sym.
    #
    # privies are param(s) of symbols
    # e.g. add_permissions(:public_access, :view_catalog)
    #
    def add_permissions(sym, *privies)
			ug = find_by_sym(sym)
			raise NameError.new("#{sym} is not defined.") if ug.nil?
			privies.each do |priv|
				ug.permissions << Permission.find_or_create_by_name(convert_reference_name(priv))
			end
    end
    
    #
    # Use this in your migrations to remove permissions from a user group 
    # identified by sym.
    #
    # privies are param(s) of symbols
    # e.g. add_permissions(:catalog_management, :manage_categories,
    #                     :manage_products)
    #
    def remove_permissions(sym, *privies)
			ug = find_by_sym(sym)
			raise NameError.new("#{sym} is not defined.") if ug.nil?
			privies.each do |priv|
				ug.permissions.delete Permission.find_by_name(convert_reference_name(priv))
			end
    end
    
    #
    # Use this in your migrations to delete the user group identified by sym.
    #
    def delete_record(sym)
      ug = find_by_sym(sym)
      ug.destroy unless ug.nil?
    end
    
		#
		# Use this for the management screen to restrict user group list to the
    # user.  This will prevent a user from creating a user with more power than
    # him/herself.
    # 
    # Public Access and Registered Users groups are automatically assigned, 
    # so having it on the management screen is just confusing and will lead
    # to errors by mistakingly removing them.
		#
		def find_assignable_for_user(usr)
			if usr.administrator?
				find :all, 
							:conditions => "name != 'Public Access' and name != 'Registered Users'", 
							:order => :name
			else
				find_by_sql <<-SQL
					select user_groups.* from user_groups, user_groups_users
					where user_groups.id = user_groups_users.user_group_id
						and user_groups.name != 'Public Access'
						and user_groups.name != 'Registered Users'
						and user_groups_users.user_id = #{usr.id}	 
					order by user_groups.name
				SQL
      end
    end

		#
		# Use this for the content associations to restrict user group list for
    # content association to the current user. 
    # 
    # For example, in a content management system, I may be able creat pages
    # but want to restrict the users who can view the page.  This will return
    # a list of user groups I can grant access to this page.
    # 
		#
		def find_content_assignable_for_user(usr)
			if usr.administrator?
				find :all
			else
				find_by_sql <<-SQL
					select user_groups.* from user_groups, user_groups_users
					where user_groups.id = user_groups_users.user_group_id
						and user_groups_users.user_id = #{usr.id}	 
					order by user_groups.name
				SQL
      end
    end
  end # end class block
  
  #
  # Return an array of the permissions for the UserGroup object
  #
  def all_permissions
    if permissions.empty?
      sym = convert_reference_name(self.name)
      Lockdown::UserGroups.static_permissions(sym)
    else
			syms_from_names(permissions)
    end
  rescue Exception => e
    []
  end

	def all_users
		User.find_by_sql <<-SQL
			select users.* 
			from users, user_groups_users
			where users.id = user_groups_users.user_id 
			and user_groups_users.user_group_id = #{self.id}
			SQL
	end

	def access_rights
		Lockdown::Permissions.access_rights_for  syms_from_names(self.permissions)
  end

	def private_record?
		Lockdown::UserGroups.respond_to? convert_reference_name(self.name) 
  end

	def system_assigned?
		self.private_record?
  end

	def protect_private
		if self.private_record?
			raise SecurityError, "Trying to update a private UserGroup"
		end
  end
end
