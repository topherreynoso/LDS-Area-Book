class FamiliesController < ApplicationController
  before_action :signed_in, only: [:ward, :investigators, :watch, :new, :create, :edit, :update, :destroy, :import, :confirm]
  before_action :authorized_user, only: [:ward, :investigators, :watch, :new, :create, :edit, :update, :destroy]
  before_action :admin_user, only: [:import, :confirm]

  def ward
    # prepare the ward decryptor
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # find all families that are not investigators or archived
    @families = Family.where("investigator = ? and archived = ?", false, false)
    @families.each do |family|
      family.encrypted_password = ward_password
    end
    @families = @families.sort_by(&:decrypted_name).paginate(page: params[:page], :per_page => 8)
  end

  def investigators
    # prepare the ward decryptor
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # find all families that are investigators and not archived
    @families = Family.where("investigator = ? and archived = ?", true, false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @families = @families.sort_by(&:decrypted_name).paginate(page: params[:page], :per_page => 8)
  end

  def watch
    # a family was selected to add to the watch list, decrypt all fields and set the ward password in order to re-encrypt and save
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)
    if params[:add_family]
      new_family = Family.find(params[:add_family])
      new_family.name = @ward_decryptor.decrypt_and_verify(new_family.name)
      new_family.email = @ward_decryptor.decrypt_and_verify(new_family.email)
      new_family.phone = @ward_decryptor.decrypt_and_verify(new_family.phone)
      new_family.address = @ward_decryptor.decrypt_and_verify(new_family.address)
      new_family.children = @ward_decryptor.decrypt_and_verify(new_family.children)
      new_family.watched = true
      new_family.encrypted_password = cookies[:ward_password]
      new_family.save

    # a family was selected to remove from the watch list, decrypt all fields and set the ward password in order to re-encrypt and save
    elsif params[:remove_family]
      remove_family = Family.find(params[:remove_family])
      remove_family.name = @ward_decryptor.decrypt_and_verify(remove_family.name)
      remove_family.email = @ward_decryptor.decrypt_and_verify(remove_family.email)
      remove_family.phone = @ward_decryptor.decrypt_and_verify(remove_family.phone)
      remove_family.address = @ward_decryptor.decrypt_and_verify(remove_family.address)
      remove_family.children = @ward_decryptor.decrypt_and_verify(remove_family.children)
      remove_family.watched = false
      remove_family.encrypted_password = cookies[:ward_password]
      remove_family.save
    end

    # get all families that are being watched so they can be selected for removal, set the ward password so their names can be decrypted
    @watched_families = Family.where("watched = ? and archived = ?", true, false)
    @watched_families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @watched_families = @watched_families.sort_by(&:decrypted_name)
    @families = @watched_families.paginate(page: params[:page], :per_page => 8)

    # get all families that are not being watched so they can be added, set the ward password so their names can be decrypted
    @unwatched_families = Family.where("watched = ? and archived = ?", false, false)
    @unwatched_families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @unwatched_families = @unwatched_families .sort_by(&:decrypted_name)

    # if the ward decryptor is not valid, let the user know that they need to reenter the ward password
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

  def import
    # a file was uploaded for importing
    if params[:file]

      # set the ward_decryptor
      @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

      # find all records that need to be added, archived, or updated
      import_families = Family.import(params[:file], cookies[:ward_password])

      # if the imported file is not properly formatted, show the error and return to the import page
      if import_families == false
        flash[:error] = "The selected csv file is not properly formatted. Please redownload and select the latest ward csv."
        redirect_to import_path

      # if there are no families, return to the root path
      elsif import_families.nil? || import_families.count == 0
        flash[:success] = "All items up to date. No import necessary."
        redirect_to root_path

      # families need to be added, archived, or updated
      else
        # get all families that are currently in the ward and not archived, set the ward password on each so that their names can be decrypted
        @ward_families = Family.where("investigator = ? and archived = ?", false, false)
        @ward_families.each do |family|
          family.encrypted_password = cookies[:ward_password]
        end

        # get all archived families, set the ward password on each so that their names can be decrypted
        @archived_families = Family.where("investigator = ? and archived = ?", false, true)
        @archived_families.each do |family|
          family.encrypted_password = cookies[:ward_password]
        end

        # prepare arrays of families for adding, removing, and updating
        @add_families = []
        @remove_families = []
        @update_families = []
        import_families.each do |family|

          # ensure that each imported family has the ward password set for re-encrypting
          family.encrypted_password = cookies[:ward_password]

          # if a record exists for the imported family, add it to updating array if it has changed, otherwise add it to the remove array
          if Family.exists?(family.id)
            if family.changed?
              @update_families << family
            else
              @remove_families << family
            end

          # if a record does not exist for the imported family, include it in the add array
          else
            @add_families << family
          end
        end
      end
    end
  end

  def confirm
    # get all families that were in the import file and prepare the ward decryptor
    add_families = params[:add_families] if params[:add_families]
    remove_families = params[:remove_families] if params[:remove_families]
    update_families = params[:update_families] if params[:update_families]
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # if there are families checked to add, create a new family record and fill it with the values and set the ward password for encrypting
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

    # if there are families checked to remove, set archived to true, set ward password for encrypting
    if remove_families && remove_families.count > 0
      remove_families.each do |f|
        if f[1][:confirmed_change] == "1"
          family = Family.find(f[1][:id].to_i)
          family.name = @ward_decryptor.decrypt_and_verify(family.name)
          family.phone = @ward_decryptor.decrypt_and_verify(family.phone)
          family.email = @ward_decryptor.decrypt_and_verify(family.email)
          family.address = @ward_decryptor.decrypt_and_verify(family.address)
          family.children = @ward_decryptor.decrypt_and_verify(family.children)
          family.confirmed_change = false
          family.archived = true
          family.encrypted_password = cookies[:ward_password]
          family.save
        end
      end
    end

    # if there are families checked to update, set ward password for encrypting
    if update_families && update_families.count > 0
      update_families.each do |f|
        if f[1][:confirmed_change] == "1"
          family = Family.find(f[1][:id].to_i)
          family.name = @ward_decryptor.decrypt_and_verify(family.name)
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

    # if the ward decryptor is not valid, let the user know that they need to re-enter the ward password
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

  def new
  	@family = Family.new
  end

  def create
    # create a record for the new family, set the ward password for encrypting or show the errors with the new family
  	@family = Family.new(family_params)
    @family.encrypted_password = cookies[:ward_password]
    if @family.save

      # if the new family is an investigator redirect to the investigators otherwise redirect to the ward list
      if @family.investigator?
      	redirect_to investigators_path
      else
      	redirect_to ward_list_path
      end
    else
      render 'new'
    end
  end

  def edit
    # find the family for editing, prepare the ward decryptor and decrypt any fields that aren't empty
  	@family = Family.find(params[:id])
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)
    @name = @ward_decryptor.decrypt_and_verify(@family.name)
    @phone = @family.phone
    @email = @family.email
    @address = @family.address
    @children = @family.children
    @phone = @ward_decryptor.decrypt_and_verify(@family.phone) if !@family.phone.nil? && @family.phone != ""
    @email = @ward_decryptor.decrypt_and_verify(@family.email) if !@family.email.nil? && @family.email != ""
    @address = @ward_decryptor.decrypt_and_verify(@family.address) if !@family.address.nil? && @family.address != ""
    @children = @ward_decryptor.decrypt_and_verify(@family.children) if !@family.children.nil? && @family.children != ""

    # if the ward decryptor is not valid, let the user know that they need to re-enter the ward password
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

  def update
    # find the family to update, set the ward password for encypting and update attributes otherwise show errors
  	@family = Family.find(params[:id])
    @family.encrypted_password = cookies[:ward_password]
    if @family.update_attributes(family_params)

      # if the family was an investigator, go to the investigators page
      if @family.investigator?
      	redirect_to investigators_path

      # otherwise go to the ward list page
      else
      	redirect_to ward_list_path
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

    def signed_in
      # if the user is not signed in then redirect to the sign in path
      unless signed_in?
        store_location
        redirect_to signin_path, notice: 'You must sign in to access this area.'
      end
    end

    def authorized_user
      # only allow access if ward access has been approved and the ward password is valid
      if !current_ward?
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      elsif !ward_password?
        store_location
        redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password in order to access this area.'
      end
    end

    def admin_user
      # only allow admins or master users access
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless current_user.admin?
    end

end
