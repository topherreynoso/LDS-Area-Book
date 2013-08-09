class ActivitiesController < ApplicationController
  before_action :authorized_user, only: [:new, :create, :destroy, :edit, :update, :reports, :archive]

  def new
  	@activity = Activity.new

    # prepare the ward decryptor
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # only allow the user to assign activities to families that are not archived
    @families = Family.where("archived = ?", false)

    # in order to display decrypted family names get the user's ward password from the session
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @families = @families.sort_by(&:decrypted_name)
  end

  def create
    # change the date to the proper format
    date = params[:activity][:activity_date]
    params[:activity][:activity_date] = Date.strptime(date, "%m/%d/%y")
  	
    # prepare the new activity record and assign the current user as its author
    @activity = Activity.new(activity_params)
  	@activity.user_id = current_user.id

    # save the new activity and view the family's report or show errors
    if @activity.save
      redirect_to reports_path(:family_id => @activity.family_id)
    else
      render 'new'
    end
  end

  def destroy
    # find the family for this activity, destroy the activity, then view the family's report
    family_id = Activity.find(params[:id]).family_id
    Activity.find(params[:id]).destroy
    redirect_to reports_path(:family_id => family_id)
  end

  def edit
    # find the activity to edit
    @activity = Activity.find(params[:id])

    # prepare the ward decryptor
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # find all of the families that are not archived and use the ward password from the session to decrypt all family names
    @families = Family.where("archived = ?", false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @families = @families.sort_by(&:decrypted_name)
  end

  def update
    # change the date to the proper format
    date = params[:activity][:activity_date]
    params[:activity][:activity_date] = Date.strptime(date, "%m/%d/%y")

    # update the activity and redirect to the family's report or show the errors
    @activity = Activity.find(params[:id])
    if @activity.update_attributes(activity_params)
      redirect_to reports_path(:family_id => @activity.family_id)
    else
      render 'edit'
    end
  end

  def reports
    # prepare the ward decryptor
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)

    # the selected report is for a family, retrieve the family and all activities reported for it
    if params[:family_id]
      @selected_family = Family.find(params[:family_id])
      @activities = @selected_family.activities.paginate(page: params[:page], :per_page => 7)

    # the selected report is for a time period, retrieve all activities reported in that time period
    elsif params[:activity_date]
      @report_date = params[:activity_date]
      @activities = Activity.where("activity_date > ?", @report_date).joins(:family).where(
                                    :families => {:archived => false}).paginate(page: params[:page], :per_page => 10)

    # no report is selected so show all activities reported
    else
      @activities = Activity.joins(:family).where(:families => {:archived => false}).paginate(page: params[:page], :per_page => 10)
    end

    # find all of the families that are not archived and use the ward password from the session to decrypt all family names
    @families = Family.where("archived = ?", false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @families = @families.sort_by(&:decrypted_name)
  end

  def archive
    # a family was selected for archiving, decrypt all fields, set the ward password so the fields can be re-encrypted and saved
    @ward_decryptor = ActiveSupport::MessageEncryptor.new(ward_password)
    if params[:archive_family]
      archive_family = Family.find(params[:archive_family])
      archive_family.name = @ward_decryptor.decrypt_and_verify(archive_family.name)
      archive_family.email = @ward_decryptor.decrypt_and_verify(archive_family.email) if !archive_family.email.nil? && archive_family.email != ""
      archive_family.phone = @ward_decryptor.decrypt_and_verify(archive_family.phone) if !archive_family.phone.nil? && archive_family.phone != ""
      archive_family.address = @ward_decryptor.decrypt_and_verify(archive_family.address) if !archive_family.address.nil? && archive_family.address != ""
      archive_family.children = @ward_decryptor.decrypt_and_verify(archive_family.children) if !archive_family.children.nil? && archive_family.children != ""
      archive_family.encrypted_password = cookies[:ward_password]
      archive_family.archived = true
      archive_family.save

    # a family was selected for unarchiving, decrypt all fields, set the ward password so the fields can be re-encrypted and saved
    elsif params[:unarchive_id]
      unarchive_family = Family.find(params[:unarchive_id])
      unarchive_family.name = @ward_decryptor.decrypt_and_verify(unarchive_family.name)
      unarchive_family.email = @ward_decryptor.decrypt_and_verify(unarchive_family.email) if !unarchive_family.email.nil? && unarchive_family.email != ""
      unarchive_family.phone = @ward_decryptor.decrypt_and_verify(unarchive_family.phone) if !unarchive_family.phone.nil? && unarchive_family.phone != ""
      unarchive_family.address = @ward_decryptor.decrypt_and_verify(unarchive_family.address) if !unarchive_family.address.nil? && unarchive_family.address != ""
      unarchive_family.children = @ward_decryptor.decrypt_and_verify(unarchive_family.children) if !unarchive_family.children.nil? && unarchive_family.children != ""
      unarchive_family.encrypted_password = cookies[:ward_password]
      unarchive_family.archived = false
      unarchive_family.save
    end

    # find all of the families that are not archived and use the ward password from the session to decrypt all family names
    @families = Family.where("archived = ?", true)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    @families = @families.sort_by(&:decrypted_name)

    # a family was selected, retrieve all activities for display
    if params[:family_id]
      @selected_family = Family.find(params[:family_id])
      @activities = @selected_family.activities
    end

    # if the ward decryptor is not valid, let the user know that they need to re-enter the ward password
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

  private

    def activity_params
      params.require(:activity).permit(:family_id, :user_id, :activity_date, :notes, :reported_by, :visit)
    end

    # Before filters

    def authorized_user
      # make sure the user is signed in and is an authorized user
      if signed_in?
        if !current_ward?
          redirect_to root_path, notice: 'You do not have permission to access this area.'
        elsif !ward_password?
          store_location
          redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password in order to access this area.'
        end
      else
        store_location
        redirect_to signin_path, notice: 'Please sign in to access this area.'
      end
    end

end
