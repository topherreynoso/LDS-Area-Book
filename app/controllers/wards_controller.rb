class WardsController < ApplicationController
  before_action :signed_in_user, only: [:new, :create, :password, :confirm_password]
  before_action :super_user, only: [:edit, :destroy, :change_password, :update]
  before_action :master_user, only: [:index]

  def index
    # get all wards
    @wards = Ward.paginate(page: params[:page], :per_page => 7)
  end

  def new
    # the user is already associated with another ward so send them to the root page
    if current_user.ward_id || !current_ward.nil?
      redirect_to root_path, notice: 'You are already associated with a ward. Please leave this ward in order to create a new one.'
    # prepare a new ward record
    else
      @ward = Ward.new
    end
  end

  def create
    # only allow users who are not already associated with a ward to create new wards
    if current_ward
      flash[:error] = "You are already associated with a ward. Please leave this ward in order to create a new one."
      redirect_to root_path
    else
      # prepare a new record for the ward and make sure that the password was entered and confirmed
      @ward = Ward.new(ward_params)
      if !@ward.confirm.nil? && @ward.confirm.length > 5
        if @ward.confirm == @ward.confirm_again

          # use the password to create an encrypted confirm string based on the unit string and save it or show errors
          password = @ward.confirm
          encrypted_password = OpenSSL::Digest::SHA256.new(password).digest
          encrypt = ActiveSupport::MessageEncryptor.new(encrypted_password)
          @ward.confirm = encrypt.encrypt_and_sign(@ward.unit)
          @ward.confirm_again = ""
          if @ward.save

            # create a new database for the new ward, separated from other wards
            Apartment::Database.create(@ward.unit)

            # associate the current user with the new ward and make the user an admin
            current_user.ward_id = @ward.id
            current_user.ward_confirmed = true
            current_user.admin = true
            current_user.skip_validation = true
            user_id = current_user.id
            current_user.save
            current_user.skip_validation = false

            # sign the user back in since some attributes and permissions may have changed
            sign_in User.find(user_id)
            set_ward_password password
            redirect_to root_path, notice: "#{@ward.name} Ward successfully created."
          else
            render 'new'
          end

        # the password was not entered the same in the confirm line so let the user know to select a new one
        else
          flash[:error] = "The ward password you entered did not match. Please enter the same password twice."
          render 'new'
        end
      else
        flash[:error] = "The ward password must be at least 6 characters long. Please enter a valid password."
        render 'new'
      end
    end
  end

  def destroy
    # retrieve the ward record
    ward = Ward.find(params[:id])

    # unassociate all users from this ward
    ward.users.each do |user|
      user.ward_id = nil
      user.ward_confirmed = false
      user.admin = false if !user.master?
      user.save
    end

    # delete the database with all ward information
    Apartment::Database.drop(ward.unit)

    # if the deleted ward is the current_ward, make sure that there is no ward set in this session and go to the root page
    set_ward nil if ward == current_ward
    ward.destroy
    flash[:success] = "The ward and all of its records were successfully deleted."
    redirect_to root_path
  end

  def edit
    # retrieve the ward record to be updated
    @ward = Ward.find(params[:id])
  end

  def update
    # retrieve the ward record, apply the updates, and go to the root page otherwise show errors
    @ward = Ward.find(params[:id])
    if @ward.update_attributes(ward_params)
      flash[:success] = "Your ward name was successfully updated."
      redirect_to root_path
    else
      render 'edit'
    end
  end

  def password
  end

  def confirm_password
    # encrypt the password and create the encryptor
    if params[:password]
      password = params[:password]
      encrypted_password = OpenSSL::Digest::SHA256.new(password).digest
      new_enc = ActiveSupport::MessageEncryptor.new(encrypted_password)

      # ensure that the encryptor properly decrypts the confirm string, which should be the same as the unit string after being decrypted
      if new_enc.decrypt_and_verify(current_ward.confirm) == current_ward.unit

        # set the ward password to allow encryption/decryption of ward information during this user's session
        set_ward_password password
        redirect_to root_path
      end
    end

  # if the password does not create a valid encryptor, let the user know that the password is invalid
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to password_path, notice: 'Your password was not valid. Please re-enter your password.'
  end

  def change_password
    # ensure that the new password has been entered and confirmed
    new_password = params[:password]
    old_password = params[:old_password]
    ward_id = current_ward.id
    if new_password == params[:password_confirm]

      # make sure that the new password is at least six characters in length
      if new_password.length > 5

        # as long as a password already exists for the ward, make sure it produces a valid encryptor
        if old_password != ""
          old_encrypted_password = OpenSSL::Digest::SHA256.new(old_password).digest
          old_enc = ActiveSupport::MessageEncryptor.new(old_encrypted_password)
          new_encrypted_password = OpenSSL::Digest::SHA256.new(new_password).digest
          new_enc = ActiveSupport::MessageEncryptor.new(new_encrypted_password)
          if old_enc.decrypt_and_verify(current_ward.confirm) == current_ward.unit
            
            # for each family in the ward, make sure that all sensitive data is decrypted and then re-encrypted using the new password
            Family.all.each do |family|
              family.name = old_enc.decrypt_and_verify(family.name)
              family.phone = old_enc.decrypt_and_verify(family.phone) if !family.phone.nil? && family.phone != ""
              family.email = old_enc.decrypt_and_verify(family.email) if !family.email.nil? && family.email != ""
              family.address = old_enc.decrypt_and_verify(family.address) if !family.address.nil? && family.address != ""
              family.children = old_enc.decrypt_and_verify(family.children) if !family.children.nil? && family.children != ""
              family.encrypted_password = new_encrypted_password
              family.save
            end

            # re-encrypt the ward unit and save the encrypted version as the confirm string and save changes
            current_ward.confirm = new_enc.encrypt_and_sign(current_ward.unit)
            current_ward.save

            # reassign the current ward since it has been updated, also set the new password in the user's session and go to the root page
            set_ward Ward.find(ward_id)
            set_ward_password new_password
            redirect_to root_path, notice: 'Your area book password has been updated.'
          end
        else

          # the old password was not entered, if there is no pre-existing password then encrypt the new one and create an encryptor from it
          if current_ward.confirm == nil
            new_encrypted_password = OpenSSL::Digest::SHA256.new(new_password).digest
            new_enc = ActiveSupport::MessageEncryptor.new(new_encrypted_password)

            # encrypt all of the sensitive family information
            Family.all.each do |family|
              family.encrypted_password = new_encrypted_password
              family.update_attributes(:name => family.name, :email => family.email, :phone => family.phone, :address => family.address, 
                                       :children => family.children)
            end

            # encrypt the ward unit string and store it as the confirm string
            current_ward.confirm = new_enc.encrypt_and_sign(current_ward.unit)
            current_ward.save

            # reassign the current ward since it has been updated, also set the new password in the user's session and go to the root page
            set_ward Ward.find(ward_id)
            set_ward_password new_password
            redirect_to root_path, notice: 'Your area book password has been updated.'

          # no password was entered but the ward has a password so let the user know that the password is necessary
          else
            redirect_to edit_ward_path(current_ward), notice: 'The current password you entered was invalid.'
          end
        end

      # let the user know that the new password is not long enough
      else
        redirect_to edit_ward_path(current_ward), notice: 'The new password must be at least 6 characters long.'
      end

    # let the user know that the new password did not match the confirmed password
    else
      redirect_to edit_ward_path(current_ward), notice: 'The new password and the confirmation did not match.'
    end

  # if the decryptor is not valid, let the user know that the password was invalid
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to edit_ward_path(current_ward), notice: 'The current password you entered was invalid.'
  end

  private

    def ward_params
      # authorized users can access all attributes of a ward
      params.require(:ward).permit(:name, :unit, :confirm, :confirm_again)
    end

    def signed_in_user
      # only allow access to users that are signed in
      redirect_to root_path, notice: 'Please sign in to access this area.' unless signed_in?
    end

    def super_user
      # only allow access to admin and master users
      unless signed_in? && (current_user.master || current_user.admin)
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end

    def master_user
      # only allow access to master users
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless signed_in? && current_user.master
    end
end
