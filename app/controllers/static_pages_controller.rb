class StaticPagesController < ApplicationController

  def index
  	if signed_in?
  	  redirect_to ward_path
  	end
  end

  def help
  end
end
