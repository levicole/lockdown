require "lockdown"

module Lockdown
  #
  #
  # Permissions are used to group access rights into logical components.
  # Each method defined in the Permissions module represents an array
  # of methods from a controller (or multiple controllers.)
  # 
  # Controller methods available are: 
  #
  #   # Returns all methods from all controllers
  #   all_controllers
  #  
  #   # Returns all methods from all controllers listed
  #   all_methods :controller1, controller2, ...
  #  
  #   # For a single controller, returns only methods listed
  #   only_methods :controller1, :method1, :method2, ...
  #  
  #   # For a single controller, returns all methods except the methods listed
  #   all_except_methods :controller1, :method1, :method2, ...
  #
  #   They all return an array of controller/action.  For example, if you had a
  #   standard REST controller called products this would be the result:
  #
  #
  #     all_methods :products  => [ "products/index , "products/show",
  #                                 "products/new", "products/edit",
  #                                 "products/create", "products/update",
  #                                 "products/destroy"]
  #
  module Permissions
    class << self
      include Lockdown::ControllerInspector
      
      def[](sym)
				raise NameError.new("#{sym} is not defined") unless respond_to?(sym)
				send(sym)
      end
      
      def access_rights_for(ary)
        ary.collect{|m| send(m)}.flatten
      end

      def all
        all_controllers
      end
      
      def sessions_management
        all_methods :sessions
      end
    end # end class block
  end # end Permissions module
  
  #
  # UserGroups are used to group Permissions together to define role type
  # functionality. Users may belong to multiple groups.
  # 
  module UserGroups
    class << self
			def[](sym)
				permissions(sym).collect{|rec| Lockdown::Permissions[rec]}.flatten
      end

			def permissions(sym)
				if self.private_records.include?(sym)
					return self.send(sym)
				end

			  static_permissions(sym)
      end

			def static_permissions(sym)
				raise NameError.new("#{sym} is not defined") unless respond_to?(sym) 
				send(sym)
      end

      #
      # This method defines which UserGroups cannot be managed
      # via the management screens. 
      # 
      # Users can still be assigned to these groups.
      #
			def private_records
        [:administrators]
      end
      #
      # This method defines which UserGroups have limited access
      # via the management screens. Deletion is not allowed.
      # 
      # Users can still be assigned to these groups.
      #
      def protected_records
        [:public_access, :registered_users]
      end
      
      # ** The administrator method is "special", please don't rename.
      #			If you remove/rename, etc... YOU WILL BREAK STUFF
      #
      # Standard administrator user group.
      # Please don't alter without careful consideration.
      #
      def administrators
        [:all]
      end
      
      # ** The public_access method is "special", please don't rename.
      #			If you remove/rename, etc... YOU WILL BREAK STUFF
      #
      # Standard public_access user group.  
      #
      # Feel free to add Permissions to the array without issue.
      #
      # **Notice:  All permissions added to this public_access group will not be
      #             restricted to logged in users.
      #             So be careful what you add here!
      #
      def public_access
        [:sessions_management] 
      end
      
      # ** The registered_users method is "special", please don't rename.
      #			Not as special as the others, but still...
      #
			# All newly created users are assigned to this User Group by default
			#
			def registered_users
				#[:my_account]
      end

      #
      # Define your own user groups below
      #
    end # end class block
  end # end UserGroups module
end # end Lockdown module
