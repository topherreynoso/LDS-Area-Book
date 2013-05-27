class UsersController < ApplicationController
  before_action :signed_in_user, only: [:index, :edit, :new, :update, :create, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: [:new, :create, :destroy, :index]

  def index
    @users = User.paginate(page: params[:page])
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
      if @user.update_attributes(admin_user_params)
        redirect_to users_path
      else
        render 'edit'
      end
    end
  end

  def create
    @user = User.new(user_params)
    if User.all.count == 0
      @user.admin = true
    end
    if @user.save
      redirect_to root_path
    else
      render 'new'
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
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :active)
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
