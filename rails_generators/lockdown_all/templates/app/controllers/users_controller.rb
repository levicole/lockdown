class UsersController < ApplicationController
	before_filter :find_user, :only => [:show, :edit, :update, :destroy]
	after_filter :update_user_groups, :only => [:create, :update]
  # GET /users
  # GET /users.xml
  def index
    @users = User.all
    logger.info "===============> access rights: #{session[:access_rights].join("\n")}" unless session[:access_rights] == :all
    logger.info "===============> is: #{current_user_is_admin?}"
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
		@user = User.new
		@profile = Profile.new
    @user_groups_for_user = UserGroup.find_assignable_for_user(current_user)
		respond_to do |format|
     format.html # new.html.erb
     format.xml  { render :xml => @user }
		end
  end

  # GET /users/1/edit
  def edit
    @user_groups_for_user = UserGroup.find_assignable_for_user(current_user)
  end
  
  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    @profile = Profile.new(params[:profile])

    @user.profile = @profile
		if @user.save
			flash[:notice] = "Thanks for signing up!"
			redirect_to(users_path)
		else
			flash[:error] = "Please correct the following issues"
			render :action => "new" 
    end
  end
  
  # PUT /users/1
  # PUT /users/1.xml
  def update
		@user.profile.attributes = params[:profile]
		@user.attributes = params[:user]

    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully updated.'
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

	def change_password 
		render :update do |page|
			page.replace_html 'password', :partial => 'password'
		end
	end

	private

	def find_user
		# Skip test if current user is an administrator
		unless current_user_is_admin? 
			# Raise error if id not = current logged in user
			raise SecurityError.new if (current_user_id != params[:id].to_i)
		end
		@user = User.find(params[:id])
		raise SecurityError.new if @user.nil?
		@profile = @user.profile
	end

	def update_user_groups
		new_ug_ids = params.collect{|p| p[0].split("_")[1].to_i if p[0] =~ /^ug_/}.compact
		#
		# Removed previously associated user_groups if not checked this time.
		#
		@user.user_groups.dup.each do |g|
			#Don't remove the automatically assigned user groups
			next if g.system_assigned?
			@user.user_groups.delete(g) unless new_ug_ids.include?(g.id)
    end
		# 
		# Add in the new permissions
		#
		new_ug_ids.each do |id|
			next if @user.user_group_ids.include?(id)
			@user.user_groups << UserGroup.find(id)
    end
  end
end
