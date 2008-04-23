module Lockdown
  # 1 hour
  SESSION_TIMEOUT = 60 * 60
  
  module Session
    protected
    include Lockdown::Helper
    def set_session_user(user)
      if user.nil?
        session.each do |key,value|
          session[key] = nil if key.to_s =~ /^user_|access_/
        end
        return
      end
      session[:user_id] = user.id
      session[:user_name] =  user.full_name
      session[:user_profile_id] = user.profile.id
      session[:access_rights] = user.access_rights
      if user.user_groups
        session[:user_groups] = syms_from_names(user.user_groups)
      end
    end
      
    def current_user
      return User.find(current_user_id, :include => [:profile, :user_groups])
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
      
    def current_user_is_admin?
      access_to_user_group? :administrators
    end

    #
    # Does the current user have access to the user group: grp?
    #
    def current_user_group_access?(grp)
      return true if current_user_is_admin?
      access_to_user_group? grp
    end

    #
    # Does the current user have access to at least one permission
    # in the user group?
    #
    def current_user_access_in_group?(grp)
      return true if current_user_is_admin?
      Lockdown::UserGroups.permissions(grp).each do |perm|
        return true if access_to_perm?(perm)
      end
      false
    end

    #
    # Does the current user have the permission: perm?
    #
    def current_user_permission_access?(perm)
      return true if current_user_is_admin?
      access_to_perm? perm
    end

    #
    # If I don't have a user_id, it's a visitor
    #
    def current_user_is_visitor?
      !logged_in?
    end
  
    def logged_in?
      current_user_id > 0
    end

    private

    def access_to_user_group?(grp)
      unless session[:user_groups].nil?
        session[:user_groups].include?(grp) 
      else
        false
      end
    end

    def access_to_perm?(perm)
      Lockdown::Permissions[perm].each do |ar|
        if session[:access_rights] && session[:access_rights].include?(ar)
          return true 
        end
      end
      false
    end
  end # Session module
end # Lockdown module

Merb::Controller.send :include, Lockdown::Session

#ActionController::Base.send :include, Lockdown::Session
#ActionController::Base.send :helper_method, :logged_in?, 
#                                           :current_user,
#                                           :current_user_name, 
#                                           :current_user_id, 
#                                           :current_profile_id,
#                                           :current_user_access_in_group?


