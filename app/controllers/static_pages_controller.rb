class StaticPagesController < ApplicationController

  def index
    # only allow signed in users with verified emails to access the ward list or ward request page
  	if signed_in? && current_user.email_confirmed?
      if !current_ward.nil? || current_user.master?
        redirect_to ward_list_path
      else
        @wards = Ward.paginate(page: params[:page], :per_page => 8)
      end
    else
      @new_auth_code = SecureRandom.hex(6)
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
