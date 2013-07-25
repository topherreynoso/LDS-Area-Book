class UsersController < ApplicationController
  before_action :correct_user,   only: [:edit, :update]
  before_action :super_user,     only: [:index, :destroy]

  def index
    if current_user.master? && current_ward.nil?
      @users = User.all
    else
      @users = User.where(:ward_id => current_ward.id)
    end
    @users = @users.paginate(page: params[:page]) if !@users.nil?
  end

  def confirm
    require 'rubygems'
    require 'mechanize'
    agent = Mechanize.new
    resp = agent.get('https://ldsaccount.lds.org/sign-in/go/profileSummary.jsf')
    form = resp.forms.second
    form['userName'] = params[:username]
    form['j_password'] = params[:password]
    page = form.click_button
    name = page.search('dd')[5]
    if !name.nil?
      @user = User.new
      @username = name.text.to_s
      @email = page.search('dd')[6].text.to_s
      @user.name = @username
      @user.email = @email
    else
      flash.now[:error] = 'The lds.org username or password you entered is incorrect.'
      render 'new'
    end
  end

  def new
    if current_user
      if current_user.admin? || current_user.master?
  	    @user = User.new
      else
        redirect_to root_path
      end
    end 
  end

  def edit
  end

  def update
    @user = User.find(params[:id])
    if current_user?(@user)
      if params[:user][:ward_id] != @user.ward_id
        @user.skip_validation = true
        @user.ward_confirmed = false
      end
      if @user.update_attributes(user_params)
        redirect_to root_path
      else
        render 'edit'
      end
    else
      @user.skip_validation = true
      update_params = nil
      if current_user.master?
        update_params = master_user_params
      else 
        update_params = admin_user_params
      end
      if @user.update_attributes(update_params)
        @user.skip_validation = false
        redirect_to users_path
      else
        render 'edit'
      end
    end
  end

  def create
    @user = User.new(user_params)
    existing_user = User.find_by_email(@user.email)
    if current_user && (current_user.admin? || current_user.master?)
      if !existing_user.nil? && existing_user.ward_confirmed && existing_user.ward_id
        flash.now[:error] = 'Email address is associated with an active user in another ward. Have the user go to their settings to leave the previous ward.'
        render 'new'
      else
        if !existing_user.nil? && (!existing_user.ward_confirmed? || existing_user.ward_id.nil?)
          @user = existing_user
          @user.skip_validation = true
        end
        @user.ward_id = current_ward.id
        @user.ward_confirmed = true
        @user.admin = true if User.find_by_ward_id(current_ward.id).nil?
        if @user.save
          @user.skip_validation = false
          redirect_to root_path
        else
          render 'new'
        end
      end
    else
      if @user.save
        sign_in @user
        flash[:success] = "Welcome to Ward Area Book"
        redirect_to root_path
      else
        if !existing_user.nil?
          flash.now[:error] = 'Email address is associated with an existing account.'
        else
          flash.now[:error] = 'Invalid password. Password must be at least six characters long.'
        end
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
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :ward_id, :ward_confirmed, :email_confirmed)
    end

    def admin_user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :ward_id, :ward_confirmed)
    end

    def master_user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation, :admin, :master, :ward_id, :ward_confirmed)
    end

    # Before filters

    def correct_user
      @user = User.find(params[:id])
      unless signed_in? && (current_user?(@user) || (current_user.admin? && @user.ward_id == current_user.ward_id) || current_user.master?)
        redirect_to(root_path)
      end
    end

    def super_user
      redirect_to(root_path) unless signed_in? && (current_user.admin? || current_user.master?)
    end
end
