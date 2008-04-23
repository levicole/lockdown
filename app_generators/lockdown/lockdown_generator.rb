class LockdownGenerator < RubiGen::Base
  LIB_DIR = "lib/lockdown"
  GEM_DIR =  File.join File.expand_path(File.dirname(__FILE__)), ".."

  def manifest
    record do |m|
      m.directory(LIB_DIR)

      src_access_file = File.join(GEM_DIR, "templates", "access.rb")
      dest_access_file = File.join(LIB_DIR, "access.rb")
      
      m.file(src_access_file, dest_access_file)
      
      puts <<-MSG
      ... Copied access.rb template to lib/lockdown
      MSG
      
      src_session_file = File.join(GEM_DIR, "templates", "session.rb")
      dest_session_file = File.join(LIB_DIR, "session.rb")
      
      m.file(src_session_file, dest_session_file)
      
      puts <<-MSG
      ... Copied sesion.rb template to lib/lockdown
      MSG
    end
  end
end

