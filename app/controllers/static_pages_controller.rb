class StaticPagesController < ApplicationController

  def index
  	if signed_in? && (!current_ward.nil? || current_user.master?)
  	  redirect_to wardlist_path
  	else
  	  @wards = Ward.paginate(page: params[:page], :per_page => 10)
  	end
  end

  def help
  end
end
