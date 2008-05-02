class LockdownAllGenerator < Rails::Generator::Base
  attr_accessor :file_name

  def manifest
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory 'app/helpers'
      m.directory 'app/models'
      m.directory 'app/views'
      m.directory 'app/views/users'
      m.directory 'app/views/user_groups'
      m.directory 'app/views/permissions'
      m.directory 'app/views/sessions'
      m.directory 'app/controllers'

      #Controllers
      m.file "app/controllers/permissions_controller.rb",
							"app/controllers/permissions_controller.rb"

      m.file "app/controllers/users_controller.rb",
							"app/controllers/users_controller.rb"

      m.file "app/controllers/user_groups_controller.rb",
							"app/controllers/user_groups_controller.rb"

      m.file "app/controllers/sessions_controller.rb",
							"app/controllers/sessions_controller.rb"

      #Models
      m.file "app/models/permission.rb",
							"app/models/permission.rb"

      m.file "app/models/user.rb",
							"app/models/user.rb"

      m.file "app/models/user_group.rb",
							"app/models/user_group.rb"

      m.file "app/models/profile.rb",
							"app/models/profile.rb"




      #Route file (i like having them on individual lines)
      m.route_resources "permissions"
      m.route_resources "user_groups"
      m.route_resources "users"
      m.route_resources "sessions"

      #Helpers
      m.file "app/helpers/permissions_helper.rb",
							"app/helpers/permissions_helper.rb"

      m.file "app/helpers/users_helper.rb",
							"app/helpers/users_helper.rb"

      m.file "app/helpers/user_groups_helper.rb",
							"app/helpers/user_groups_helper.rb"

      #Views
      copy_views(m, "users")

      m.file "app/views/users/_password.html.erb",
							"app/views/users/_password.html.erb"

      copy_views(m, "user_groups")

      m.file "app/views/permissions/_data.html.erb",
							"app/views/permissions/_data.html.erb"

      m.file "app/views/permissions/index.html.erb",
							"app/views/permissions/index.html.erb"

      m.file "app/views/permissions/show.html.erb",
							"app/views/permissions/show.html.erb"

      m.file "app/views/sessions/new.html.erb",
							"app/views/sessions/new.html.erb"

      #Migrations
			begin
				m.migration_template "db/migrate/create_profiles.rb", "db/migrate", 
															:migration_file_name => "create_profiles"
			rescue 
				puts "Profiles migration exists"
			end

			begin
      m.migration_template "db/migrate/create_users.rb", "db/migrate", 
														:migration_file_name => "create_users"

			rescue
				puts "Users migration exists"
			end

			begin
      m.migration_template "db/migrate/create_user_groups.rb", "db/migrate", 
														:migration_file_name => "create_user_groups"

			rescue 
				puts "User Groups migration exists"
			end

			begin
      m.migration_template "db/migrate/create_permissions.rb", "db/migrate", 
														:migration_file_name => "create_permissions"

			rescue
				puts "Permissions migration exists"
			end

			begin
      m.migration_template "db/migrate/create_admin_user_and_user_group.rb", 
														"db/migrate", 
														:migration_file_name => "create_admin_user_and_user_group"

			rescue
				puts "Admin User Group... migration exists"
			end

			add_standard_routes(m)
			add_permissions(m)
    end
  end

  protected

  def banner
<<-EOS
Installs the lockdown framework to managing users user_groups 
and viewing permissions. Also includes a login screen.

USAGE: #{$0} #{spec.name} 
EOS
  end

	def copy_views(m, vw)
		m.file "app/views/#{vw}/_data.html.erb", "app/views/#{vw}/_data.html.erb"
		m.file "app/views/#{vw}/_form.html.erb", "app/views/#{vw}/_form.html.erb"
		m.file "app/views/#{vw}/index.html.erb", "app/views/#{vw}/index.html.erb"
		m.file "app/views/#{vw}/show.html.erb", "app/views/#{vw}/show.html.erb"
		m.file "app/views/#{vw}/edit.html.erb", "app/views/#{vw}/edit.html.erb"
		m.file "app/views/#{vw}/new.html.erb", "app/views/#{vw}/new.html.erb"
	end

	def add_standard_routes(m)
		home = %Q(map.home '', :controller => 'sessions', :action => 'new')
		login = %Q(map.login '/login', :controller => 'sessions', :action => 'new')
		logout =%Q(map.logout '/logout', :controller => 'sessions', :action => 'destroy')
			
		sentinel = 'ActionController::Routing::Routes.draw do |map|'

		m.gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
				"#{match}\n #{home}\n #{login}\n #{logout}"
		end
  end

	def add_permissions(m)
perms = <<-PERMS

  set_permission :sessions_management, all_methods(:sessions)

  set_permission :users_management, all_methods(:users)

  set_permission :user_groups_management, all_methods(:user_groups)

  set_permission :permissions_management, all_methods(:permissions)

  set_permission :my_account, only_methods(:users, :edit, :update, :show)

PERMS

		sentinel = '# Define your permissions here:'
		m.gsub_file 'lib/lockdown/init.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
				"#{match}\n#{perms}"
		end

predefined_user_groups = <<-PUG
  set_public_access :sessions_management

  set_protected_access :my_account
PUG

		sentinel = '# Define the built-in user groups here:'
		m.gsub_file 'lib/lockdown/init.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
				"#{match}\n#{predefined_user_groups}"
		end


	end
end
