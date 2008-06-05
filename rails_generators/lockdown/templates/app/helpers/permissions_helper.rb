module PermissionsHelper
  def permission_name_value
    h @permission.name 
  end

  def permission_access_rights_value
    Lockdown::System.access_rights_for_permission(@permission).collect{|r| r}.join("<br/>") 
  end

  def permission_users_value
    @permission.all_users.collect{|u| link_to_or_show(u.full_name, u)}.join("<br/>")
  end
end
