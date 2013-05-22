class FamiliesController < ApplicationController
  before_action :signed_in_user, only: [:ward, :new, :create, :edit, :update, :destroy]

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
      if new_family.save
        flash[:success] = "Added #{new_family.name} to watch list."
      end
    elsif params[:remove_family]
      remove_family = Family.find(params[:remove_family])
      remove_family.watched = false
      if remove_family.save
        flash[:success] = "Removed #{remove_family.name} from watch list."
      end
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
      flash[:success] = "New record created for #{@family.name}."
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
      flash[:success] = "Information updated for #{@family.name}."
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
