class LockdownGenerator < RubiGen::Base
  
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])
  
  default_options :author => "Andrew Stone"
  
  attr_reader :name, :framework
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    @framework = runtime_options[:framework]
  end

  def manifest
    record do |m|
      m.directory "lib/lockdown"
      m.template "session.rb", "lib/lockdown/session.rb"
      m.file "access.rb", "lib/lockdown/access.rb"
    end
  end
end
