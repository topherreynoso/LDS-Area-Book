class StaticPagesController < ApplicationController

  def index
    # only allow signed in users to the ward list otherwise send them to find a ward
  	if signed_in? && (!current_ward.nil? || current_user.master?)
  	  redirect_to ward_list_path
  	else
  	  @wards = Ward.paginate(page: params[:page], :per_page => 8)
  	end
  end

  def help
  end

  def tutorial
    # set the type of tutorial page
  	@type = params[:type] if params[:type]
  end

  def contact
  end
  
end
