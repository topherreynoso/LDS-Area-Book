class WardsController < ApplicationController
  before_action :signed_in_user, only: [:leaders, :confirm, :create, :edit, :update, :password, :confirm_password]
  before_action :super_user, only: [:edit, :destroy, :change_password]
  before_action :master_user, only: [:new, :index, :switch]

  def index
    @wards = Ward.paginate(page: params[:page], :per_page => 7)
  end

  def new
  	@ward = Ward.new
  end

  def leaders
  end

  def confirm
    require 'rubygems'
    require 'mechanize'

    agent = Mechanize.new
    resp = agent.get('https://www.lds.org/mls/mbr/records/member-list?lang=engf')
    records_page = resp.form_with(:action => '/login.html') do |f|
      f.username = params[:username]
      f.password = params[:password]
    end.click_button
    number = records_page.search('#heading-unit-number').first
    if !number.nil?
      @ward = Ward.new
      @unit_number = number.text.to_s
      name = records_page.search('#heading-unit-name').first.text.to_s
      @ward_name = name[0..-5]
      @ward.name = @ward_name
      @ward.unit = @unit_number
    else
      redirect_to leaders_path, notice: 'The lds.org username or password you entered is incorrect.'
    end
  end

  def create
    @ward = Ward.new(ward_params)
    if @ward.save
      Apartment::Database.create(@ward.unit)
      if current_user.master?
        redirect_to wards_path, notice: "#{@ward.name} Ward successfully created."
      else
        current_user.ward_id = @ward.id
        current_user.ward_confirmed = true
        current_user.admin = true
        current_user.save
        sign_in User.find(current_user.id)
        redirect_to root_path, notice: "#{@ward.name} Ward successfully created."
      end
    else
      if current_user.master?
        render 'new'
      else
        redirect_to root_path, notice: "An area book already exists for unit number #{@ward.unit}."
      end
    end
  end

  def destroy
    ward = Ward.find(params[:id])
    ward.users.each do |user|
      user.ward_id = nil
      user.ward_confirmed = false
      user.admin = false if !user.master?
      user.save
    end
    Apartment::Database.drop(ward.unit)
    set_ward nil if ward == current_ward
    ward.destroy
    redirect_to wards_path
  end

  def edit
    @ward = Ward.find(params[:id])
  end

  def update
    @ward = Ward.find(params[:id])
    if @ward.update_attributes(ward_params)
      if current_user.master?
        redirect_to wards_path
      else
        redirect_to users_path
      end
    else
      render 'edit'
    end
  end

  def switch
  	if params[:ward_id]
  	  ward = Ward.find(params[:ward_id])
  	  set_ward ward
    elsif current_user.master?
      set_ward nil
  	end
  	redirect_to root_path
  end

  def password
  end

  def confirm_password
    if params[:password]
      password = params[:password]
      encrypted_password = OpenSSL::Digest::SHA256.new(password).digest
      new_enc = ActiveSupport::MessageEncryptor.new(encrypted_password)
      if new_enc.decrypt_and_verify(current_ward.confirm) == current_ward.unit
        set_ward_password password
        redirect_to root_path
      end
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to password_path, notice: 'Your password was not valid. Please re-enter your password.'
  end

  def change_password
    new_password = params[:password]
    old_password = params[:old_password]
    ward_id = current_ward.id
    if new_password == params[:password_confirm]
      if new_password.length > 5
        if old_password != ""
          old_encrypted_password = OpenSSL::Digest::SHA256.new(old_password).digest
          old_enc = ActiveSupport::MessageEncryptor.new(old_encrypted_password)
          new_encrypted_password = OpenSSL::Digest::SHA256.new(new_password).digest
          new_enc = ActiveSupport::MessageEncryptor.new(new_encrypted_password)
          if old_enc.decrypt_and_verify(current_ward.confirm) == current_ward.unit
            Family.all.each do |family|
              family.name = old_enc.decrypt_and_verify(family.name)
              family.phone = old_enc.decrypt_and_verify(family.phone) if !family.phone.nil? && family.phone != ""
              family.email = old_enc.decrypt_and_verify(family.email) if !family.email.nil? && family.email != ""
              family.address = old_enc.decrypt_and_verify(family.address) if !family.address.nil? && family.address != ""
              family.children = old_enc.decrypt_and_verify(family.children) if !family.children.nil? && family.children != ""
              family.encrypted_password = new_encrypted_password
              family.save
            end
            current_ward.confirm = new_enc.encrypt_and_sign(current_ward.unit)
            current_ward.save
            set_ward Ward.find(ward_id)
            set_ward_password new_encrypted_password
            redirect_to root_path, notice: 'Your area book password has been updated.'
          end
        else
          if current_ward.confirm == nil
            new_encrypted_password = OpenSSL::Digest::SHA256.new(new_password).digest
            new_enc = ActiveSupport::MessageEncryptor.new(new_encrypted_password)
            Family.all.each do |family|
              family.encrypted_password = new_encrypted_password
              family.update_attributes(:name => family.name, :email => family.email, :phone => family.phone, :address => family.address, 
                                       :children => family.children)
            end
            current_ward.confirm = new_enc.encrypt_and_sign(current_ward.unit)
            current_ward.save
            set_ward Ward.find(ward_id)
            set_ward_password new_encrypted_password
            redirect_to root_path, notice: 'Your area book password has been updated.'
          else
            redirect_to edit_ward_path(current_ward), notice: 'The current password you entered was invalid.'
          end
        end
      else
        redirect_to edit_ward_path(current_ward), notice: 'The new password must be at least 6 characters long.'
      end
    else
      redirect_to edit_ward_path(current_ward), notice: 'The new password and the confirmation did not match.'
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to edit_ward_path(current_ward), notice: 'The current password you entered was invalid.'
  end

  private

    def ward_params
      params.require(:ward).permit(:name, :unit)
    end

    def signed_in_user
      redirect_to root_path, notice: 'Please sign in to access this area.' unless signed_in?
    end

    def super_user
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless signed_in? && (current_user.master || current_user.admin)
    end

    def master_user
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless signed_in? && current_user.master
    end
end
