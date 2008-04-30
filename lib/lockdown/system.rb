module Lockdown
  class System
    class << self
			include Lockdown::ControllerInspector

      attr_accessor :options #:nodoc:

      attr_accessor :permissions #:nodoc:
      attr_accessor :user_groups #:nodoc:

      # :public_access allows access to all
      attr_accessor :public_access #:nodoc:
      # :protected_access will restrict access to authenticated users.
      attr_accessor :protected_access #:nodoc:

      # Future functionality:
      # :private_access will restrict access to model data to their creators.
      # attr_accessor :private_access #:nodoc:

      def configure(&block)
				self.set_defaults
        self.instance_eval(&block)
      end

      def [](key)
        (@options||={})[key]
      end

			def []=(key,val)
        @options[key] = val
      end

      def set_permission(name, *method_arrays)
        @permissions[name] ||= []
        method_arrays.each{|ary| @permissions[name] += ary}
      end

			def get_permissions
				@permissions.keys
      end

      def set_user_group(name, *perms)
        @user_groups[name] ||= []
        perms.each{|perm| @user_groups[name].push(perm)}
      end

			def get_user_groups
				@user_groups.keys
      end

			def set_public_access(*perms)
				perms.each{|perm| @public_access += @permissions[perm]}
			end

			def set_protected_access(*perms)
				perms.each{|perm| @protected_access += @permissions[perm]}
			end
			
			def standard_authorized_user_rights
				Lockdown::System.public_access + Lockdown::System.protected_access 
      end

			def user_access_rights(usr)
				return :all if usr.administrator?
				@user_groups.collect do |grp| 
					grp.access_rights
        end + Lockdown::System.standard_authorized_user_rights 
			end

			#
			# Create a user group record in the database
			#
			def create_user_group(str_sym)
				return unless @options[:use_db_models]
				UserGroup.create(:name => string_name(str_sym))
			end

			def create_administrator_user_group
				return unless @options[:use_db_models]
				Lockdown::System.create_user_group administrator_group_symbol
  		end

			#
			# Delete a user group record from the database
			#
			def delete_user_group(str_sym)
				ug = UserGroup.find_by_name(string_name(str_sym))
				ug.destroy unless ug.nil?
			end

			#
			# Use this for the management screen to restrict user group list to the
			# user.  This will prevent a user from creating a user with more power than
			# him/her self.
			# 
			#
			def user_groups_assignable_for_user(usr)
				return [] if usr.nil?

				if usr.administrator?
					find(:all, :order => :name)
				else
					find_by_sql <<-SQL
						select user_groups.* from user_groups, user_groups_users
						where user_groups.id = user_groups_users.user_group_id
							and user_groups_users.user_id = #{usr.id}	 
						order by user_groups.name
					SQL
				end
			end

			def make_user_administrator(usr)
				usr.user_groups << UserGroup.find_or_create_by_name(administrator_group_string)
			end

			def administrator?(usr)
				user_has_user_group?(usr, administrator_group_symbol)
			end

      protected 

      def set_defaults
        @permissions = {}
        @user_groups = {}

        @public_access = []
        @protected_access = []
        @private_access = []

				@options = {
					:use_db_models => true,
					:session_timeout => (60 * 60),
					:logout_on_access_violation => false,
					:access_denied_path => "/",
					:successful_login_path => "/"
				}
      end

			private

			def user_has_user_group?(usr, sym)
				usr.user_groups.each do |ug|
					return true if convert_reference_name(ug.name) == sym
				end
				false
			end

    end # class block
  end # System class
end # Lockdown
