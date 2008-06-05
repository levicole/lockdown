module UserGroupsHelper
  def user_group_name_value
    if <%= action_name %> == "show"
       h @user_group.name 
    else
       text_field_tag "user_group[name]", @user_group.name
    end
  end

  def user_group_permissions_value
    if <%= action_name %> == "show"
       @user_group.permissions.collect{|p| p.name + "<br/>"}
    else
      rvalue = %{<ul id="all_permissions" class="checklist">}
      @all_permissions.each_with_index do |perm,i|
        bg = ( i % 2 == 0 ) ? "even" : "odd"
        input_id = "perm_#{perm.id}"
        checked = (@user_group.permission_ids.include?(perm.id) ? "checked" : "")
        bg << "_" << checked if checked.length > 0
        rvalue << <<-HTML
          <li class="#{bg}">
            <label id="lbl_#{input_id}" for="#{input_id}" onclick="do_highlight('#{input_id}')">
              <input id="#{input_id}" name="#{input_id}" type="checkbox" #{checked}/>&nbsp;&nbsp;#{perm.name}
            </label>
          </li>
        HTML
       end
       rvalue << "</ul>"
    end
  end

  def user_group_users_value
    @user_group.all_users.collect{|u| link_to_or_show(u.full_name, u)}.join("<br/>")
  end
end
