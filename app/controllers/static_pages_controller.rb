class StaticPagesController < ApplicationController

  def home
  	if signed_in?
  	  redirect_to ward_path
  	end
  end

  def help
  end
end
