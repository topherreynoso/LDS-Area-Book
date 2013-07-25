class FamiliesController < ApplicationController
  before_action :authorized_user, only: [:ward, :investigators, :watch, :new, :create, :edit, :update, :destroy]
  before_action :super_user, only: [:import, :confirm]

  def ward
  	@families = Family.where("investigator = ? and archived = ?", false, false).paginate(page: params[:page], :per_page => 7)
  end

  def investigators
    @families = Family.where("investigator = ? and archived = ?", true, false).paginate(page: params[:page], :per_page => 7)
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
    @families = Family.where("watched = ? and archived = ?", true, false).paginate(page: params[:page], :per_page => 7)
    @unwatched_families = Family.where("watched = ? and archived = ?", false, false)
  end

  def import
    if params[:file]
      import_families = Family.import(params[:file])
      if import_families == false
        flash[:error] = "The selected csv file is not properly formatted. Please redownload and select the latest ward csv."
        redirect_to import_path
      elsif import_families.nil? || import_families.count == 0
        flash[:success] = "All items up to date. No import necessary."
        redirect_to root_path
      else
        @ward_families = Family.where("investigator = ? and archived = ?", false, false)
        @archived_families = Family.where("investigator = ? and archived = ?", false, true)
        @add_families = []
        @remove_families = []
        @update_families = []
        import_families.each do |family|
          if Family.exists?(family.id)
            if family.changed?
              @update_families << family
            else
              @remove_families << family
            end
          else
            @add_families << family
          end
        end
      end
    end
  end

  def confirm
    add_families = params[:add_families] if params[:add_families]
    remove_families = params[:remove_families] if params[:remove_families]
    update_families = params[:update_families] if params[:update_families]
    if add_families && add_families.count > 0
      add_families.each do |f|
        if f[1][:confirmed_change] == "1"
          family = Family.new
          family.name = f[1][:name]
          family.phone = f[1][:phone]
          family.email = f[1][:email]
          family.address = f[1][:address]
          family.children = f[1][:children]
          family.save
        end
      end
    end
    if remove_families && remove_families.count > 0
      remove_families.each do |f|
        if f[1][:confirmed_change] == "1"
          family = Family.find(f[1][:id].to_i)
          family.confirmed_change = false
          family.archived = true
          family.save
        end
      end
    end
    if update_families && update_families.count > 0
      update_families.each do |f|
        if f[1][:confirmed_change] == "1"
          family = Family.find(f[1][:id].to_i)
          family.phone = f[1][:phone]
          family.email = f[1][:email]
          family.address = f[1][:address]
          family.children = f[1][:children]
          family.archived = f[1][:archived]
          family.save
        end
      end
    end
    redirect_to root_path
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
      	redirect_to wardlist_path
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
      	redirect_to wardlist_path
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

    def authorized_user
      redirect_to(root_path) unless signed_in? && (current_ward || current_user.master?)
    end

    def super_user
      redirect_to(root_path) unless signed_in? && (current_user.admin? || current_user.master?)
    end

end
