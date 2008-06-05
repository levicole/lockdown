module UsersHelper
  def profile_first_name_value
    if <%= action_name %> == "show"
      h @profile.first_name 
    else
      text_field_tag "profile[first_name]", @profile.first_name
    end
  end

  def profile_last_name_value
    if <%= action_name %> == "show"
      h @profile.last_name 
    else
      text_field_tag "profile[last_name]", @profile.last_name
    end
  end

  def profile_email_value
    if <%= action_name %> == "show"
      h @profile.email 
    else
      text_field_tag "profile[email]", @profile.email 
    end
  end

  def user_login_value
    if <%= action_name %> == "show"
      h @user.login 
    else
      text_field_tag "user[login]", @user.login
    end
  end

  def user_password_value
    if <%= action_name %> == "show"
      h "Hidden for security..."
    else
      %{<input autocomplete="off" type="password" name="user[password]" id="user_password"/>}
    end
  end

  def user_password_confirmation_value
    if <%= action_name %> == "show"
      h "Hidden for security..."
    else
      %{<input autocomplete="off" type="password" name="user[password_confirmation]" id="user_password_confirmation"/>}
    end
  end

  def user_user_groups_value
    if <%= action_name %> == "show"
      @user.user_groups.collect{|ug| ug.name + "<br/>"}
    else
      rvalue = %{<ul id="all_user_groups" class="checklist">}
      #
      # Restrict user group list to the list of the current user.
      # This prevents a user from creating someone with more access than
      # him/herself.
      #
      @user_groups_for_user.each_with_index do |ug,i|
        bg =  ( i % 2 == 0 ) ? "even" : "odd"
        input_id = "ug_#{ug.id}"
        checked = (@user.user_group_ids.include?(ug.id) ? "checked" : "")
        bg << "_" << checked if checked.length > 0
        rvalue << <<-HTML
          <li class="#{bg}">
            <label id="lbl_#{input_id}" for="#{input_id}" onclick="do_highlight('#{input_id}')">
            <input id="#{input_id}" name="#{input_id}" type="checkbox" #{checked}/>&nbsp;&nbsp;#{ug.name}
            </label>
          </li>
        HTML
      end
      rvalue << "</ul>"
    end
  end


end
