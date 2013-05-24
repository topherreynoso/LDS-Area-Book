class FamiliesController < ApplicationController
  before_action :signed_in_user, only: [:ward, :investigators, :watch, :new, :create, :edit, :update, :destroy]

  def ward
  	members = Family.where("investigator = ?", false)
    @families = members.where("archived = ?", false)
  end

  def investigators
    investigators = Family.where("investigator = ?", true)
  	@families = investigators.where("archived = ?", false)
  end

  def watch
    if params[:add_family]
      new_family = Family.find(params[:add_family])
      new_family.watched = true
      new_family.save
    elsif params[:remove_family]
      remove_family = Family.find(params[:remove_family])
      remove_family.watched = false
      remove_family.save
    end
    watched = Family.where("watched = ?", true)
    @families = watched.where("archived = ?", false)
    unwatched = Family.where("watched = ?", false)
    @unwatched_families = unwatched.where("archived = ?", false)
  end

  def new
  	@family = Family.new
  end

  def create
  	@family = Family.new(family_params)
    if @family.save
      if @family.investigator?
      	redirect_to investigators_path
      else
      	redirect_to ward_path
      end
    else
      render 'new'
    end
  end

  def edit
  	@family = Family.find(params[:id])
  end

  def update
  	@family = Family.find(params[:id])
    if @family.update_attributes(family_params)
      if @family.investigator?
      	redirect_to investigators_path
      else
      	redirect_to ward_path
      end
    else
      render 'edit'
    end
  end

  def destroy
    Family.find(params[:id]).destroy
    redirect_to archive_path
  end

  private

    def family_params
      params.require(:family).permit(:name, :phone, :email, :address, :children, :investigator)
    end

    # Before filters

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end

end
