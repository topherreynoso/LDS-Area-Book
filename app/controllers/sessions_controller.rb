class SessionsController < ApplicationController

  def new
  end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && !user.active?
      flash.now[:error] = 'Your access has been disabled. Please contact your ward clerk.'
    elsif user && user.authenticate(params[:session][:password])
      sign_in user
      if user.ward_id? && !user.master?
        ward = Ward.find(user.ward_id)
        set_ward ward
      elsif user.master?
        set_ward nil
      end
      redirect_back_or root_path
    else
      flash.now[:error] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
