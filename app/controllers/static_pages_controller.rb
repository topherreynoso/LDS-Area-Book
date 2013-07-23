class StaticPagesController < ApplicationController

  def index
  	if signed_in?
  	  redirect_to wardlist_path
  	end
  end

  def help
  end
end
