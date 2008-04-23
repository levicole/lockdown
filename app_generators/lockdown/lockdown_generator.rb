class LockdownGenerator < RubiGen::Base
  
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])
  
  default_options :author => "Andrew Stone"
  
  attr_reader :name
  
  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
  end

  def manifest
    record do |m|
      m.directory "lib/lockdown"
      m.file "session.rb", "lib/lockdown/session.rb"
      m.file "access.rb", "lib/lockdown/access.rb"
    end
  end
end
