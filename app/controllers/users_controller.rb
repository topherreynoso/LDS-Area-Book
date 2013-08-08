class UsersController < ApplicationController
  before_action :correct_user, only: [:edit, :destroy]
  before_action :authorized_user, only: [:update]
  before_action :admin_user, only: [:index]
  before_action :master_user, only: [:all]

  def all
    # show a system-wide user list
    @is_all_users = true
    @users = User.all.paginate(page: params[:page], :per_page => 8)
  end

  def index
    # only show the users in the current ward
    @users = User.where(:ward_id => current_ward.id).paginate(page: params[:page], :per_page => 8)
  end

  def new
    # only allow users who are not signed in to create new accounts
    if signed_in?
      redirect_to root_path
    else
  	  @user = User.new
    end 
  end

  def edit
  end

  def update
    # get the user record, assume that the update is not a request to join a new ward
    @user = User.find(params[:id])
    ward_request = false

    # the update is for a user's own account
    if current_user?(@user)

      # the request is to join a new ward, make sure the ward is not confirmed and the user is not an admin since they are requesting access
      if params[:user][:ward_id] && params[:user][:ward_id] != @user.ward_id
        @user.skip_validation = true
        @user.ward_confirmed = false
        ward_request = true
        @user.admin = false if ward_request && params[:user][:ward_id] == nil
      end

      # udpate the record and sign the user back in so updates take effect, otherwise show the errors
      if @user.update_attributes(user_params)
        sign_in User.find(@user.id)

        # if this is a request to access a new ward or leave a ward, let the user know that the request has been made, otherwise go to root
        if ward_request == true
          if @user.ward_id != nil
            redirect_to root_path, :flash => { :success => 'Your request has been submitted. An admin will respond to your request soon.' }
          else
            set_ward nil
            redirect_to root_path, :flash => { :success => 'Your account is no longer associated with a ward.' }
          end
        else
          redirect_to root_path, :flash => { :success => 'Your account has been updated.' }
        end
      else
        render 'edit'
      end

    # the update is being made by a master or admin user
    else

      # only allow the proper list of updateable attributes in, let admins and master users skip validation requirements
      if signed_in? && (current_user.admin? || current_user.master?)
        @user.skip_validation = true
        ward_request = true if params[:user][:ward_id] && params[:user][:ward_id] != @user.ward_id
        update_params = nil
        if current_user.master?
          update_params = master_user_params
        else 
          update_params = admin_user_params
        end

        # update the attributes and make sure the skip_validation virtual attribute is set back to false, otherwise show errors
        if @user.update_attributes(update_params)
          @user.skip_validation = false
          if ward_request
            redirect_to users_path, :flash => { :success => "The user's ward status was successfully updated." }
          else
            redirect_to users_path, :flash => { :success => 'The user account was successfully updated.'}
          end
        else
          redirect_to users_path, notice: 'An error occurred while updating the user.'
        end
      end
    end
  end

  def create
    # determine if the email is already associated with another user account
    @user = User.new(user_params)
    existing_user = User.find_by_email(@user.email)

    # only allow new users to create user accounts
    if !signed_in?

      # if the new account is successfully created, send to the root page otherwise show errors
      if @user.save
        sign_in @user
        flash[:success] = "Welcome to LDS Area Book"
        redirect_to root_path
      else
        render 'new'
      end
    else
      redirect_to root_path
    end
  end

  def destroy
    # destroy the user account and sign out, unless it is a master account that delted the user, then redirect to the root page
    User.find(params[:id]).destroy
    sign_out if signed_in? && !current_user.master?
    if !signed_in?
      flash[:success] = "Your account was deleted."
      redirect_to root_path
    else
      flash[:success] = "User account was deleted."
      render 'index'
    end 
  end

  private

    def user_params
      # regular users can alter all of their own attributes except admin and master
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :ward_id, :ward_confirmed, :email_confirmed)
    end

    def admin_user_params
      # admin users can alter other users' ward and admin status
      params.require(:user).permit(:ward_id, :ward_confirmed, :admin)
    end

    def master_user_params
      # master users can alter all attributes of users
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :ward_id, :ward_confirmed, :email_confirmed, :admin, :master)
    end

    # Before filters

    def correct_user
      # if the user is not the same account that is signed in or a master account then redirect it
      @user = User.find(params[:id])
      unless signed_in? && (current_user?(@user) || current_user.master?)
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def authorized_user
      # if the user is not the same account that is signed in or an admin or master account then redirect it
      @user = User.find(params[:id])
      unless signed_in? && (current_user?(@user) || ((current_user.admin? && @user.ward_id == current_user.ward_id) || current_user.master?))
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def admin_user
      # only allow an admin or master user access, otherwise redirect it
      unless signed_in? && current_user.admin? && !current_ward.nil?
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def master_user
      # only allow a master user access, otherwise redirect it
      unless signed_in? && current_user.master?
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end
end
