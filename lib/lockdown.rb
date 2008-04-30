$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Lockdown
  class << self
    def format_controller_action(url)
      url.split("/").delete_if{|p| p.to_i > 0 || p.length == 0}.join("/")
      url += "/index" unless url =~ /\//
      url
    end

    def format_controller(ctr)
      ctr.split("/").delete_if{|p| p.length == 0}.join("/")
    end

    def project_root
      project_related_value("Merb.root", "RAILS_ROOT")
    end
                       
    def merb_app?
      Object.const_defined?("Merb") && Merb.const_defined?("AbstractController")
    end

    def rails_app?
      Object.const_defined?("ActionController") && ActionController.const_defined?("Base")
    end

    def controller_parent
      project_related_value("Merb::Controller", "ActionController::Base")
    end

    def datamapper_orm?
      Object.const_defined?("DataMapper") && DataMapper.const_defined?("Base")
    end

    def active_record_orm?
      Object.const_defined?("ActiveRecord") && ActiveRecord.const_defined?("Base")
    end

    def orm_parent
      if datamapper_orm?
        DataMapper::Base
      elsif active_record_orm?
        ActiveRecord::Base
      else
        raise NotImplementedError, "ORM unknown to Lockdown!  Lockdown recognizes DataMapper and ActiveRecord"
      end
    end

    private

    def project_related_value(merb_val, rails_val)
      if merb_app?
        eval(merb_val)
      elsif rails_app?
        eval(rails_val)
      else
        raise NotImplementedError, "Project type unkown to Lockdown"
      end

    end
  end # class block
  
  require File.join("lockdown", "helper.rb")
  require File.join("lockdown", "controller_inspector.rb")
  require File.join("lockdown", "system.rb")
  require File.join("lockdown", "controller.rb")
  require File.join("lockdown", "model.rb")
  require File.join("lockdown", "view.rb")

  module Session
    include Lockdown::Helper

    def nil_lockdown_values
      %w(user_id user_name user_profile_id access_rights).each do |val|
        session[val] = nil if session[val]
      end
    end 
    
    #
    # Does the current user have access to at least one permission
    # in the user group?
    #
    def current_user_access_in_group?(grp)
      return true if current_user_is_admin?
        Lockdown::System.user_groups[grp].each do |perm|
          return true if access_in_perm?(perm)
        end
      false
    end

    def current_user_is_admin?
      session[:access_rights] == :all
    end

    private

    #
    # session[:access_rights] are the keys to Lockdown.
    #
    # session[:access_rights] holds the array of "controller/action" strings 
    # allowed for the user.
    #
    #
    def add_lockdown_session_values(user)
      session[:access_rights] = Lockdown::System.access_rights_for_user(user)
    end

    def access_in_perm?(perm)
      Lockdown::System.permissions[perm].each do |ar|
        return true if session_access_rights_include?(ar)
      end unless Lockdown::System.permissions[perm].nil?
      false
    end

    def session_access_rights_include?(str)
      return false unless session[:access_rights]
      session[:access_rights].include?(str)
    end
  end
end

