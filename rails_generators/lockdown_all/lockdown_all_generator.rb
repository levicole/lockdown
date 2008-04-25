class LockdownAllGenerator < RubiGen::Base
  
  default_options :author => nil
  
  attr_reader :name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @name = args.shift
  end

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
      m.file "app/controllers/permissions_controller.rb",  "app/controllers/permissions_controller.rb"
      m.file "app/controllers/users_controller.rb",        "app/controllers/users_controller.rb"
      m.file "app/controllers/user_groups_controller.rb",  "app/controllers/user_groups_controller.rb"

      #Models
      m.file "app/models/permission.rb",  "app/models/permission.rb"
      m.file "app/models/user.rb",        "app/models/user.rb"
      m.file "app/models/user_group.rb",  "app/models/user_group.rb"

      #Helpers
      m.file "app/helpers/permissions_helper.rb",  "app/helpers/permissions_helper.rb"
      m.file "app/helpers/users_helper.rb",        "app/helpers/users_helper.rb"
      m.file "app/helpers/user_groups_helper.rb",  "app/helpers/user_groups_helper.rb"

      #Views
      copy_views(m, "users")
      m.file "app/views/users/_password.html.erb", "app/views/users/_password.html.erb"

      copy_views(m, "user_groups")

      copy_views(m, "permissions")

      m.file "app/views/sessions/new.html.erb", "app/views/sessions/new.html.erb"
    end
  end

  protected
    def banner
      <<-EOS
Creates a ...

USAGE: #{$0} #{spec.name} name
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
