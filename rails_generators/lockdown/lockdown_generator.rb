if Rails::VERSION::MAJOR >= 2 && Rails::VERSION::MINOR >= 1
  class Rails::Generator::Commands::Base
    protected
    def next_migration_string(padding = 3)
      sleep(1)
      Time.now.utc.strftime("%Y%m%d%H%M%S") 
    end
  end
end

class LockdownGenerator < Rails::Generator::Base
  attr_accessor :file_name, :action_name, :namespace, :view_path, :controller_path
  def initialize(runtime_args, runtime_options = {})
    super
    if Rails::VERSION::MAJOR >= 2 && Rails::VERSION::MINOR >= 1
      @action_name = "action_name"
    else
      @action_name = "@action_name"
    end
    @namespace = options[:namespace] if options[:namespace]
    # so if the namespace option exists it sets the correct view path and controller path,
    # I didn't change the helpers path, since they are automatically loaded anyway in application_helper...
    if @namespace
      @view_path = "app/views/#{@namespace}"
      @controller_path = "app/controllers/#{@namespace}"
    else
      @view_path = "app/views"
      @controller_path = "app/controllers"
    end
  end

  def manifest
    puts @namespace
    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory 'app/helpers'
      m.directory "#{@view_path}"
      m.directory "#{@controller_path}"
      if options[:all]
        options[:management] = true
        options[:login] = true
      end
      add_management(m) if options[:management]

      add_login(m) if options[:login]

      add_models(m)
    end #record do |m|
  end

  protected

  def add_management(m)
    m.directory "#{@view_path}/users"
    m.directory "#{@view_path}/user_groups"
    m.directory "#{@view_path}/permissions"

    m.template "app/controllers/permissions_controller.rb",
      "#{@controller_path}/permissions_controller.rb"

    m.template "app/controllers/users_controller.rb",
      "#{@controller_path}/users_controller.rb"

    m.template "app/controllers/user_groups_controller.rb",
      "#{@controller_path}/user_groups_controller.rb"

    m.template "app/helpers/permissions_helper.rb",
      "app/helpers/permissions_helper.rb"

    m.template "app/helpers/users_helper.rb",
      "app/helpers/users_helper.rb"

    m.template "app/helpers/user_groups_helper.rb",
      "app/helpers/user_groups_helper.rb"

    copy_views(m, "users")

    copy_views(m, "user_groups")

    m.template "app/views/permissions/_data.html.erb",
      "#{@view_path}/permissions/_data.html.erb"

    m.template "app/views/permissions/index.html.erb",
      "#{@view_path}/permissions/index.html.erb"

    m.template "app/views/permissions/show.html.erb",
      "#{@view_path}/permissions/show.html.erb"

    if @namespace.blank?
      m.route_resources "permissions"
      m.route_resources "user_groups"
      m.route_resources "users"
    end

    add_management_permissions(m)
  end

  def add_login(m)
    m.directory "#{@view_path}/sessions"

    m.template "app/controllers/sessions_controller.rb",
      "#{@controller_path}/sessions_controller.rb"

    m.template "app/views/sessions/new.html.erb",
      "#{@view_path}/sessions/new.html.erb"
    
    m.route_resources "sessions" if @namespace.blank?

    add_login_permissions(m)
    add_login_routes(m)
  end

  def add_models(m)
    m.directory 'app/models'

    m.file "app/models/permission.rb",
      "app/models/permission.rb"

    m.file "app/models/user.rb",
      "app/models/user.rb"

    m.file "app/models/user_group.rb",
      "app/models/user_group.rb"

    m.file "app/models/profile.rb",
      "app/models/profile.rb"

    add_migrations(m) unless options[:no_migrations]
  end

  def add_migrations(m)
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
      m.migration_template "db/migrate/create_admin_user.rb", 
        "db/migrate", 
        :migration_file_name => "create_admin_user"
    rescue
      puts "Admin User Group... migration exists"
    end
  end # add_migrations

  def copy_views(m, vw)
    m.template "app/views/#{vw}/_data.html.erb", "#{@view_path}/#{vw}/_data.html.erb"
    m.template "app/views/#{vw}/_form.html.erb", "#{@view_path}/#{vw}/_form.html.erb"
    m.template "app/views/#{vw}/index.html.erb", "#{@view_path}/#{vw}/index.html.erb"
    m.template "app/views/#{vw}/show.html.erb", "#{@view_path}/#{vw}/show.html.erb"
    m.template "app/views/#{vw}/edit.html.erb", "#{@view_path}/#{vw}/edit.html.erb"
    m.template "app/views/#{vw}/new.html.erb", "#{@view_path}/#{vw}/new.html.erb"
  end

  def add_login_permissions(m)
    add_permissions m, "set_permission :sessions_management, all_methods(:#{@namespace.blank? ? "sessions" : "admin__sessions"})"
    
    add_predefined_user_group m, "set_public_access :sessions_management"
  end

  def add_management_permissions(m)
    perms = []
    perms << "set_permission :users_management, all_methods(:#{@namespace.blank? ? "users" : "#{@namespace}__users"})"
    perms << "set_permission :user_groups_management, all_methods(:#{@namespace.blank? ? "user_groups" : "#{@namespace}__user_groups"})"
    perms << "set_permission :permissions_management, all_methods(:#{@namespace.blank? ? "permissions" : "#{@namespace}__permissions"})"
    perms << "set_permission :my_account, only_methods(:#{@namespace.blank? ? "users" : "#{@namespace}__users"}, :edit, :update, :show)"

    add_permissions m, perms.join("\n  ")
    
    add_predefined_user_group m, "set_protected_access :my_account"
  end

  def add_permissions(m, str)
    sentinel = '# Define your permissions here:'
    m.gsub_file 'lib/lockdown/init.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n  #{str}"
    end
  end

  def add_predefined_user_group(m, str)
    sentinel = '# Define the built-in user groups here:'
    m.gsub_file 'lib/lockdown/init.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n  #{str}"
    end
  end

  def add_login_routes(m)
    if @namespace.blank?
      home = %Q(\tmap.home '', :controller => 'sessions', :action => 'new')
      login = %Q(\tmap.login '/login', :controller => 'sessions', :action => 'new')
      logout =%Q(\tmap.logout '/logout', :controller => 'sessions', :action => 'destroy')
      routes = [home, login, logout].join("\n\n")
    else
      home = %Q(\tmap.home '', :controller => '#{@namespace}/sessions', :action => 'new')
      login = %Q(\tmap.login '/login', :controller => '#{@namespace}/sessions', :action => 'new')
      logout =%Q(\tmap.logout '/logout', :controller => '#{@namespace}/sessions', :action => 'destroy')
      resources = %Q(\tmap.namespace :#{@namespace} do |#{@namespace}|\n\t\t#{@namespace}.resources :sessions\n\t\t#{@namespace}.resources :permissions\n\t\t#{@namespace}.resources :users\n\t\t#{@namespace}.resources :user_groups\n\tend)
      routes = [home,  login, logout, resources].join("\n\n")
    end
    sentinel = 'ActionController::Routing::Routes.draw do |map|'
                
    m.gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
      "#{match}\n #{routes}\n"
    end
  end

  def banner
<<-EOS
Installs the lockdown framework to managing users user_groups 
and viewing permissions. Also includes a login screen.

USAGE: #{$0} #{spec.name} 
EOS
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--all",
      "Install all Lockdown templates") { |v| options[:all] = v }
    opt.on("--namespace NAMESPACE",
      "Install lockdown templates with a namespace") { |v| options[:namespace] = v }
    opt.on("--models",
      "Install only models and migrations (skip migrations by --no_migrations).") { |v| options[:models] = v }
    opt.on("--management",
      "Install  management functionality.  Which is --all minus --login. All models (migrations) included. ") { |v| options[:management] = v }
    opt.on("--login",
      "Install login functionality.  Which is --all minus --management. All models (migrations) included. ") { |v| options[:login] = v }
    opt.on("--no_migrations",
      "Skip migrations installation") { |v| options[:no_migrations] = v }
  end

end
