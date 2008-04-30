module PermissionsHelper
  def permission_name_value
		h @permission.name 
  end

  def permission_access_rights_value
		@permission.access_rights.collect{|r| r}.join("<br/>") if @permission.access_rights
  end

	def permission_users_value
		@permission.all_users.collect{|u| link_to_or_show(u.full_name, u)}.join("<br/>")
  end
end
