module Lockdown
  # 1 hour
  SESSION_TIMEOUT = 60 * 60
  
  #
  # The Lockdown gem defines additional Session methods:
  #
  #  current_user_is_admin?: returns true if user is assigned 
  #  administrator rights.
  #
  #  nil_lockdown_values:  This will nil all session values starting with 
  #  user_ or access_ or expiry
  #
  #  current_user_access_in_group?(grp):  grp is a symbol referencing a 
  #  Lockdown::UserGroups method such as :registered_users
  #  Will return true if the session[:access_rights] contain at 
  #  least one match to the access_right list associated to the group
  #
  module Session
    protected

    def set_session_user(user)
      if user.nil?
        nil_lockdown_values
        return
      end
      session[:user_id] = user.id
      session[:user_name] =  user.full_name
      session[:user_profile_id] = user.profile.id

      #
      # If you remove this method, you will not gain access to any 
      # protected resources
      #
      add_lockdown_session_values(user)
    end
      
    def logged_in?
      current_user_id > 0
    end

    def current_user_id
      return session[:user_id] || -1
    end

    def current_user_name
      session[:user_name]
    end
      
    def current_profile_id
      return session[:user_profile_id] || -1
    end

    def current_user
      return current_user_id > 0 ? User.find(current_user_id, :include => [:profile, :user_groups]) : nil
    end
  
  end # Session module
end # Lockdown module

<% if framework == "merb" -%>
Merb::Controller.send :include, Lockdown::Session
<% else %>
ActionController::Base.send :include, Lockdown::Session
ActionController::Base.send :helper_method, :logged_in?, 
                                           :current_user,
                                           :current_user_name, 
                                           :current_user_id, 
                                           :current_profile_id,
                                           :current_user_is_admin?,
                                           :current_user_access_in_group?
<% end -%>
