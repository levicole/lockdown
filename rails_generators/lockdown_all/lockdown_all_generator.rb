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



      #Migrations
      m.migration_template "db/migrate/create_profiles.rb", "db/migrate", 
														:migration_file_name => "create_profiles"

      m.migration_template "db/migrate/create_users.rb", "db/migrate", 
														:migration_file_name => "create_users"

      m.migration_template "db/migrate/create_user_groups.rb", "db/migrate", 
														:migration_file_name => "create_user_groups"

      m.migration_template "db/migrate/create_permissions.rb", "db/migrate", 
														:migration_file_name => "create_permissions"

      m.migration_template "db/migrate/create_admin_user_and_user_group.rb", 
														"db/migrate", 
														:migration_file_name => "create_admin_user_and_user_group"

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
end
