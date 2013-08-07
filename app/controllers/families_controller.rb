class FamiliesController < ApplicationController
  before_action :authorized_user, only: [:ward, :investigators, :watch, :new, :create, :edit, :update, :destroy, :import, :confirm]
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
      new_family.name = ward_decryptor.decrypt_and_verify(new_family.name)
      new_family.email = ward_decryptor.decrypt_and_verify(new_family.email)
      new_family.phone = ward_decryptor.decrypt_and_verify(new_family.phone)
      new_family.address = ward_decryptor.decrypt_and_verify(new_family.address)
      new_family.children = ward_decryptor.decrypt_and_verify(new_family.children)
      new_family.watched = true
      new_family.encrypted_password = cookies[:ward_password]
      new_family.save
    elsif params[:remove_family]
      remove_family = Family.find(params[:remove_family])
      remove_family.name = ward_decryptor.decrypt_and_verify(remove_family.name)
      remove_family.email = ward_decryptor.decrypt_and_verify(remove_family.email)
      remove_family.phone = ward_decryptor.decrypt_and_verify(remove_family.phone)
      remove_family.address = ward_decryptor.decrypt_and_verify(remove_family.address)
      remove_family.children = ward_decryptor.decrypt_and_verify(remove_family.children)
      remove_family.watched = false
      remove_family.encrypted_password = cookies[:ward_password]
      remove_family.save
    end
    @families = Family.where("watched = ? and archived = ?", true, false).paginate(page: params[:page], :per_page => 7)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @unwatched_families = Family.where("watched = ? and archived = ?", false, false)
    @unwatched_families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
  end

  def import
    if params[:file]
      import_families = Family.import(params[:file], cookies[:ward_password])
      if import_families == false
        flash[:error] = "The selected csv file is not properly formatted. Please redownload and select the latest ward csv."
        redirect_to import_path
      elsif import_families.nil? || import_families.count == 0
        flash[:success] = "All items up to date. No import necessary."
        redirect_to root_path
      else
        @ward_families = Family.where("investigator = ? and archived = ?", false, false)
        @ward_families.each do |family|
          family.encrypted_password = cookies[:ward_password]
        end
        @archived_families = Family.where("investigator = ? and archived = ?", false, true)
        @archived_families.each do |family|
          @archived_families.encrypted_password = cookies[:ward_password]
        end
        @add_families = []
        @remove_families = []
        @update_families = []
        import_families.each do |family|
          family.encrypted_password = cookies[:ward_password]
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
          family.encrypted_password = cookies[:ward_password]
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
          family.encrypted_password = cookies[:ward_password]
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
          family.encrypted_password = cookies[:ward_password]
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
    @family.encrypted_password = cookies[:ward_password]
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
    @name = ward_decryptor.decrypt_and_verify(@family.name)
    @phone = @family.phone
    @email = @family.email
    @address = @family.address
    @children = @family.children
    @phone = ward_decryptor.decrypt_and_verify(@family.phone) if !@family.phone.nil? && @family.phone != ""
    @email = ward_decryptor.decrypt_and_verify(@family.email) if !@family.email.nil? && @family.email != ""
    @address = ward_decryptor.decrypt_and_verify(@family.address) if !@family.address.nil? && @family.address != ""
    @children = ward_decryptor.decrypt_and_verify(@family.children) if !@family.children.nil? && @family.children != ""
  end

  def update
  	@family = Family.find(params[:id])
    @family.encrypted_password = cookies[:ward_password]
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
      if signed_in?
        if !current_user.master
          if !current_ward?
            redirect_to root_path, notice: 'You do not have permission to access this area.'
          elsif !ward_decryptor_valid?
            redirect_to password_path
          end
        end
      else
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def super_user
      unless signed_in? && (current_user.admin? || current_user.master?)
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

end
