module Lockdown
  module Controller#:nodoc:
    #
    # Core Controller locking methods
    #
    module Core
      def self.included(base)
        base.send :include, Lockdown::Controller::Core::InstanceMethods
      end
      
      module InstanceMethods
        def configure_lock_down
          check_session_expiry
          store_location
        end

        def set_current_user
          login_from_basic_auth? unless logged_in?
          if logged_in?
            Thread.current[:profile_id] = current_profile_id
            Thread.current[:client_id] = current_client_id if respond_to? :current_client_id
          end
        end
  
        def check_request_authorization
          unless authorized?(path_from_hash(params))
            raise SecurityError, "Authorization failed for params #{params.inspect}"
          end
        end
      
        def redirect_back_or_default(default)
          session[:prevpage] ? send_to(session[:prevpage]) : send_to(default)
        end

        private

        def path_allowed?(url)
          req = Lockdown.format_controller_action(url)
          session[:access_rights] ||= Lockdown::System.public_access
          session[:access_rights].each do |ar|
            return true if req == ar
          end
          false
        end
        
        def check_session_expiry
          if session[:expiry_time] && session[:expiry_time] < Time.now
            nil_lockdown_values
          end
          session[:expiry_time] = Time.now + Lockdown::System.fetch(:session_timeout)
        end
              
        def store_location
          if (request.method == :get) && (session[:thispage] != sent_from_uri)
            session[:prevpage] = session[:thispage] || ''
            session[:thispage] = sent_from_uri
          end
        end
      
        # Called from current_user.  Now, attempt to login by
        # basic authentication information.
        def login_from_basic_auth?
          username, passwd = get_auth_data
          if username && passwd
            set_session_user User.authenticate(username, passwd)
          end
        end
    
        @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
        # gets BASIC auth info
        def get_auth_data
          auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
          auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
          return auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil] 
        end
      end # InstanceMethods
    end # Core

    #
    # Merb Controller locking methods
    #
    module Merb
      def self.included(base)
        base.send :include, Lockdown::Controller::Merb::InstanceMethods

        base.before :set_current_user
        base.before :configure_lock_down
        base.before :check_request_authorization
      end

      module InstanceMethods
        def self.included(base)
          base.class_eval do
            alias :send_to  :redirect
          end
          base.send :include, Lockdown::Controller::Core
        end

        def sent_from_uri
          request.uri
        end

        def authorized?(path)
          return true if current_user_is_admin?

          # See if path is known
          if path_allowed?(path)
            true 
          else
            false
          end
        end
      
        # Can log Error => e if desired, I don't desire to now.
        # For now, just send home, but will probably make this configurable
        def access_denied(e)
          send_to Lockdown::Session[:access_denied_path]
        end

        def path_from_hash(hsh)
          return hsh if hsh.is_a?(String)
          hsh = hsh.to_hash if hsh.is_a?(Mash)
          hsh['controller'].to_s + "/" + hsh['action'].to_s
        end
        
      end # InstanceMethods
    end # Merb

    #
    # Rails Controller locking methods
    #
    module Rails
      def self.included(base)
        base.send :include, Lockdown::Controller::Rails::InstanceMethods

        base.before_filter do |controller|
          controller.set_current_user
          controller.configure_lock_down
          controller.check_request_authorization
        end

        base.send :helper_method, :authorized?

        base.filter_parameter_logging :password, :password_confirmation
      
        base.rescue_from SecurityError,
          :with => proc{|e| access_denied(e)}
      end

      module InstanceMethods
        def self.included(base)
          base.class_eval do
            alias :send_to  :redirect_to
          end
          base.send :include, Lockdown::Controller::Core
        end

        def sent_from_uri
          request.request_uri
        end

        def authorized?(url)
          return true if current_user_is_admin?

          url_parts = URI::split(url)
        
          path = url_parts[5]

          # See if path is known
          return true if path_allowed?(path)

          # Test to see if url contains id 
          parts = path.split("/").collect{|p| p unless p =~ /\A\d+\z/}.compact
          new_path = parts.join("/")

          return true if path_allowed?(new_path)

          # Test for a named routed
          begin
            hsh = ActionController::Routing::Routes.recognize_path(url)
            unless hsh.nil?
              return true if path_allowed?(path_from_hash(hsh)) 
            end
          rescue Exception => e
            # continue on
          end

          false
        end
      
        def access_denied(e)
					if Lockdown::System.fetch(:logout_on_access_violation)
						reset_session
					end
          respond_to do |accepts|
            accepts.html do
              store_location
              send_to Lockdown::System.fetch(:access_denied_path)
            end
            accepts.xml do
              headers["Status"] = "Unauthorized"
              headers["WWW-Authenticate"] = %(Basic realm="Web Password")
              render :text => e.message, :status => "401 Unauthorized"
            end
          end
          false
        end

        def path_from_hash(hsh)
          hsh[:controller].to_s + "/" + hsh[:action].to_s
        end
        
      end # InstanceMethods
    end # Rails
  end # Controller
end # Lockdown

if Lockdown.merb_app?
  Merb::Controller.send :include, Lockdown::Controller::Merb
elsif Lockdown.rails_app?
  ActionController::Base.send :include, Lockdown::Controller::Rails
end

