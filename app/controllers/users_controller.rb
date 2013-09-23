class UsersController < ApplicationController
  before_action :signed_in, only: [:edit, :destroy, :update, :index, :all]
  before_action :email_verified, only: [:destroy, :index, :all]
  before_action :correct_user, only: [:edit]
  before_action :correct_user_or_master, only: [:destroy]
  before_action :correct_user_or_admin, only: [:update]
  before_action :admin_user, only: [:index]
  before_action :master_user, only: [:all]

  def all
    # show a system-wide user list
    @is_all_users = true

    # start with all users
    @users = User.all
    
    # the user selected a range of letters so find all users in that range
    if params[:scope]
      @all_users = @users
      @users = []
      @all_users.each do |user|
        @users << user if params[:scope].include?(user.name[0,1])
      end
    end

    # paginate the users
    @users = @users.paginate(page: params[:page], :per_page => 8)
  end

  def index
    # only show the users in the current ward
    @users = User.where(:ward_id => current_ward.id)

    # the user selected a range of letters so find all users in that range
    if params[:scope]
      @all_users = @users
      @users = []
      @all_users.each do |user|
        @users << user if params[:scope].include?(user.name[0,1])
      end
    end

    # paginate the users
    @users = @users.paginate(page: params[:page], :per_page => 8)
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
    old_email = @user.email

    # the update is for a user's own account
    if current_user?(@user)

      # the request is to join or leave a ward, make sure the ward is not confirmed and the user is not an admin
      if params[:user][:ward_id] && params[:user][:ward_id] != @user.ward_id
        ward_request = true
        @user.ward_confirmed = false
        @user.ward_id = params[:user][:ward_id]
        @user.admin = false if params[:user][:ward_id] == nil
        @user.skip_validation = true
        @user.save
        @user.skip_validation = false
      end

      # udpate the record and sign the user back in so updates take effect, otherwise show the errors
      if @user.update_attributes(user_params)
        
        # the user has updated their account with a new email address or requested to resend email verification
        if params[:user][:email] && old_email != params[:user][:email]
          
          # make sure their email is not confirmed, set a new auth code and skip validations
          email_change = true
          @user.email_confirmed = false
          @user.auth_code = SecureRandom.hex(6)
          @user.skip_validation = true
          @user.save
          @user.skip_validation = false
        end

        sign_in User.find(@user.id)
        if email_change
          flash[:success] = 'A verification was sent to your new email. Please follow the link in it to verify.'
        else
          flash[:success] = 'Your account has been updated.'
        end
        redirect_to root_path
      
      # if this is a request to access or leave a ward, let the user know the request has been made, otherwise go to root
      elsif ward_request
        sign_in User.find(@user.id)
        if @user.ward_id != nil
          UserMailer.user_request_access(@user.ward_id).deliver
          flash[:success] = 'Your request has been submitted. An admin will respond to your request soon.'
        else
          set_ward nil
          flash[:success] = 'Your account is no longer associated with a ward.'
        end
        redirect_to root_path
      else
        render 'edit'
      end

    # the update is being made by a master or admin user
    else

      # only allow the proper list of updateable attributes in, let admins and master users skip validation requirements
      if signed_in? && (current_user.admin? || current_user.master?)
        @user.skip_validation = true
        if (params[:user][:ward_id] && params[:user][:ward_id] != @user.ward_id) || (params[:user][:ward_confirmed] && params[:user][:ward_confirmed] != @user.ward_confirmed)
          ward_request = true
        end
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
            UserMailer.user_access_status(@user.id).deliver
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

      # set the email auth code and, if the new account is successfully created, send an email to the root page otherwise show errors
      @user.auth_code = SecureRandom.hex(6)
      if @user.save
        sign_in @user
        flash[:success] = "Welcome to LDS Area Book. Please verify your email by following the link we sent to your address."
        UserMailer.user_email_verification(@user.id).deliver
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

  def verify
    # find the user verifying their account
    @user = User.find(params[:id])

    # the user has requested resending a verification email
    if params[:resend]
      UserMailer.user_email_verification(@user.id).deliver
      flash[:success] = "An email was sent to your account. Follow the link in the email to verify your address."

    # the user is verifying their email
    else

      # make sure that the auth code submitted matches the user's auth code
      if @user && @user.auth_code = params[:auth_code]

        # change the user's status to email confirmed and skip the validation so a password is not required to change it
        @user.email_confirmed = true
        @user.skip_validation = true

        # as long as the user saves properly, let the user know or show the error
        if @user.save
          sign_in User.find(@user.id)
          flash[:success] = "Your user email has been verified."
        else
          flash[:error] = "There was an error. Please try verifying your user email again."
        end
        @user.skip_validation = false
      else
        flash[:error] = "Your user email verification code does not match. Please resend a verification email and try again."
      end
    end
    redirect_to root_path
  end

  def reset
    # the user has followed an email link to regain access to their account
    if params[:id]
      # verify that user auth code is correct, sign them in and send them to the edit user page or let them know there was an error
      @user = User.find(params[:id])
      if params[:auth_code] && params[:auth_code] == @user.auth_code
        sign_in @user
        redirect_to edit_user_path(current_user)
      else
        redirect_to root_path, notice: 'Something was not right. Try resending an email to regain access.'
      end
    end
  end

  def send_reset
    # the user has requested access to their account, verify that an account is associated with that email address
    if params[:email]
      @user = User.find_by_email(params[:email])

      # create a new auth code and send the user an email with instructions on how to regain access
      if !@user.nil?
        @user.auth_code = SecureRandom.hex(6)
        @user.skip_validation = true
        @user.save
        @user.skip_validation = false
        UserMailer.user_regain_access(@user.id).deliver
        redirect_to root_path, notice: 'An email was sent to help you regain access to your account.'
      
      # no account is associated with that email so send them back to re-enter it
      else
        redirect_to reset_path, notice: 'There is no account associated with that email. Please enter a valid email address.'
      end
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

    def signed_in
      # if the user is not signed in, redirect them to the sign in path
      unless signed_in?
        store_location
        redirect_to signin_path, notice: 'You must sign in to access this area.'
      end
    end

    def email_verified
      # if their email address has not been verified then send them to the root page
      unless current_user.email_confirmed?
        redirect_to root_path, notice: 'You must verify your email address before you can access this area.'
      end
    end

    def correct_user
      # if the user is not the same account that is signed in or a master account then redirect it
      @user = User.find(params[:id])
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless current_user?(@user)
    end

    def correct_user_or_master
      # if it is not the user's own account or if the signed in account is not a master then redirect to root
      @user = User.find(params[:id])
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless current_user?(@user) || current_user.master?
    end

    def correct_user_or_admin
      # if it is not the user's own account or if the signed in account is not authorized to administer the user's ward then redirect to root
      @user = User.find(params[:id])
      @ward = nil
      @ward = Ward.find(@user.ward_id) if !@user.ward_id.nil?
      unless current_user?(@user) || (current_user.admin? && current_ward_is?(@ward) && ward_password?)
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def admin_user
      # only allow an admin user access, otherwise redirect it
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless current_user.admin?
    end

    def master_user
      # only allow a master user access, otherwise redirect it
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless current_user.master?
    end
end
