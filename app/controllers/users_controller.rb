class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :new, :update, :create, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: [:new, :create, :destroy, :index]

  def index
    if current_user.master? && current_ward == nil
      @users = User.all
    else
      @users = User.where(:ward_id => current_ward.id)
    end
    @users = @users.paginate(page: params[:page]) if !@users.nil?
  end

  def new
  	@user = User.new
  end

  def edit
  end

  def update
    @user = User.find(params[:id])
    if current_user?(@user)
      if @user.update_attributes(user_params)
        sign_in current_user
        redirect_to root_path
      else
        render 'edit'
      end
    else
      @user.is_admin_applying_update = true
      update_params = nil
      if current_user.master?
        update_params = master_user_params
      else 
        update_params = admin_user_params
      end
      if @user.update_attributes(update_params)
        redirect_to users_path
      else
        render 'edit'
      end
    end
  end

  def create
    @user = User.new(user_params)
    existing_user = User.find_by_email(@user.email)
    if !existing_user.nil? && existing_user.active?
      flash.now[:error] = 'That email address is already associated with an active user in another ward. That ward must deactivate this user 
                          account before you can add it to your ward.'
      render 'new'
    else
      if !existing_user.nil?
        @user = existing_user
        @user.active = true
      end
      @user.ward_id = current_ward.id
      @user.admin = true if User.all.count == 0 || User.find_by_ward_id(current_ward.id).nil?
      @user.master = true if User.all.count == 0
      if @user.save
        redirect_to root_path
      else
        render 'new'
      end
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to users_url
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def admin_user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :active, :master)
    end

    def master_user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :active, :master)
    end

    # Before filters

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end

    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless (current_user?(@user) || current_user.admin?)
    end

    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
