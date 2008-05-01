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

      attr_accessor :controller_classes #:nodoc:

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

			#
			# Create a user group record in the database
			#
			def create_user_group(str_sym)
				return unless @options[:use_db_models]
				ug = UserGroup.create(:name => string_name(str_sym))
				#
				# No need to create permissions records for administrators
				#
				ug_sym = symbol_name(ug.name)
				return if ug_sym == administrator_group_symbol

				if self.has_user_group?(ug)
					@user_groups[ug_sym].collect do |perm|
						Permission.create(:name => string_name(perm))
					end
				end
			end

			def create_administrator_user_group
				return unless @options[:use_db_models]
				Lockdown::System.create_user_group administrator_group_symbol
  		end

			#
			# Determine if the user group is defined in init.rb
			#
			def has_user_group?(ug)
				return true if symbol_name(ug.name) == administrator_group_symbol
				@user_groups.each do |key,value|
					return true if key == symbol_name(ug.name)
				end
				return false
			end

			#
			# Delete a user group record from the database
			#
			def delete_user_group(str_sym)
				ug = UserGroup.find_by_name(string_name(str_sym))
				ug.destroy unless ug.nil?
			end

			def access_rights_for_user(usr)
				return unless usr
				return :all if administrator?(usr)

			  rights = standard_authorized_user_rights

				if @options[:use_db_models]
					usr.user_groups.each do |grp|
						if @user_groups.has_key? symbol_name(grp.name)
							@user_groups[symbol_name(grp.name)].each do |perm|
								rights += @permissions[perm]
							end
						else
							grp.permissions.each do |perm|
								rights += @permissions[symbol_name(perm.name)]
							end
						end
					end
				end
				rights
			end

			def access_rights_for_perm(perm)
        (perms = @permissions[symbol_name(perm.name)]) == nil ? [] : perms 
      end

			#
			# Use this for the management screen to restrict user group list to the
			# user.  This will prevent a user from creating a user with more power than
			# him/her self.
			# 
			#
			def user_groups_assignable_for_user(usr)
				return [] if usr.nil?

				if administrator?(usr)
					UserGroup.find(:all, :order => :name)
				else
					UserGroup.find_by_sql <<-SQL
						select user_groups.* from user_groups, user_groups_users
						where user_groups.id = user_groups_users.user_group_id
							and user_groups_users.user_id = #{usr.id}	 
						order by user_groups.name
					SQL
				end
			end

			#
			# Similar to user_groups_assignable_for_user, this method should be
      # used to restrict users from creating a user group with more power than
      # they have been allowed.
			#
			def permissions_assignable_for_user(usr)
				return [] if usr.nil?
				if administrator?(usr)
					@permissions.keys.collect{|k| Permission.find_by_name(string_name(k)) }.compact
				else
					groups = user_groups_assignable_for_user(usr)
					groups.collect{|g| g.permissions}.flatten.compact
				end
			end

			def make_user_administrator(usr)
				usr.user_groups << UserGroup.find_or_create_by_name(administrator_group_string)
			end

			def administrator?(usr)
				user_has_user_group?(usr, administrator_group_symbol)
			end

			def administrator_rights
				all_controllers
      end

      def fetch_controller_class(str)
        @controller_classes.each do |klass|
          return klass if klass.name == controller_class_name(str)
        end
      end

      protected 

      def set_defaults
        @controller_classes = []
        load_controller_classes

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

      def load_controller_classes
        unless const_defined?("Application")
          require(Lockdown.project_root + "/app/controllers/application.rb")
        end

        Dir.chdir("#{Lockdown.project_root}/app/controllers") do
          Dir["**/*.rb"].sort.each do |c|
            next if c == "application.rb"
            klass = controller_class_name_from_file(c)
            require(c) unless qualified_const_defined?(klass)
            @controller_classes.push( qualified_const_get(klass) )
          end
        end
      end

      def controller_class_name_from_file(str)
        str.split(".")[0].split("/").collect{|str| camelize(str) }.join("::")
      end

      def controller_class_name(str)
        if str.include?("__")
          kontroller_class_name(str.split("__").collect{|p| camelize(p)}.join("::"))
        else
          kontroller_class_name(camelize(str))
        end
      end

      def qualified_const_defined?(klass)
        if klass =~ /::/
          namespace, klass = klass.split("::")
          eval("#{namespace}.const_defined?(#{klass})") if const_defined?(namespace)
        else
          const_defined?(klass)
        end
      end

      def qualified_const_get(klass)
        if klass =~ /::/
          namespace, klass = klass.split("::")
          eval(namespace).const_get(klass)
        else
          const_get(klass)
        end
      end
    end # class block
  end # System class
end # Lockdown
