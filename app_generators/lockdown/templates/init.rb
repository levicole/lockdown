require "lockdown"
require File.join(File.dirname(__FILE__), "session")

Lockdown::System.configure do

	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# Configuration Options
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# Options with defaults:
	#
	# Set timeout to 1 hour:
	#		options[:session_timeout] = (60 * 60)
	#
	# Set system to logout if unauthorized access is attempted:
	#		options[:logout_on_access_violation] = false
	#
	# Set redirect to path on unauthorized access attempt:
	#		options[:access_denied_path] = "/"
	#
	# Set redirect to path on successful login:
	#		options[:successful_login_path] = "/"
	#
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# Define permissions
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#		set_permission(:product_management, all_methods(:products))
	#
	#			:product_management is the name of the permission which is later
	#					referenced by the user_group method
	# 
	#			:all_methods(:products) will return an array of all controller actions
	#			for the products controller
  #			
	#				if products is your standard RESTful resource you'll get:
	#				["products/index , "products/show",
  #					"products/new", "products/edit",
  #         "products/create", "products/update",
  #         "products/destroy"]
	#
	#	You can pass multiple parameters to concat permissions such as:
	#		
	#		set_permission(:security_management,all_methods(:users),
	#																				all_methods(:user_groups),
	#																			  all_methods(:permissions) )
	#
	# In addition to all_methods(:controller) there are:
	#
	#		only_methods(:controller, :only_method_1, :only_method_2)
	#
	#		all_except_methods(:controller, :except_method_1, :except_method_2)
	#
	#	Some other sample permissions:
  #	
  #		set_permission(:sessions, all_methods(:sessions))
  #		set_permission(:my_account, only_methods(:users, :edit, :update, :show))
	# 
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# Built-in user groups
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#	You can assign the above permission to one of the built-in user groups
  #	by using the following:
  #	
	#		To allow public access on the permissions :sessions and :home:
  #		set_public_access :sessions, :home
  #		
	#		
	#		Restrict :my_account access to only authenticated users:
  #		set_protected_access :my_account
  #		
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	# Define user groups
	#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	#
	#		set_user_group(:catalog_management, :category_management, 
  #																			  :product_management) 
	# 
	#			:catalog_management is the name of the user group
	#			:category_management and :product_management refer to permission names
	#
	
	# Add your configuration below:
end 
