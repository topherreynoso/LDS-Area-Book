class ActivitiesController < ApplicationController
  before_action :authorized_user, only: [:new, :create, :destroy, :edit, :update, :reports, :archive]

  def new
  	@activity = Activity.new
    @families = Family.where("archived = ?", false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
  end

  def create
    date = params[:activity][:activity_date]
    params[:activity][:activity_date] = Date.strptime(date, "%m/%d/%y")
  	@activity = Activity.new(activity_params)
  	@activity.user_id = current_user.id
    if @activity.save
      redirect_to reports_path(:family_id => @activity.family_id)
    else
      render 'new'
    end
  end

  def destroy
    family_id = Activity.find(params[:id]).family_id
    Activity.find(params[:id]).destroy
    redirect_to reports_path(:family_id => family_id)
  end

  def edit
    @activity = Activity.find(params[:id])
    @families = Family.where("archived = ?", false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
  end

  def update
    date = params[:activity][:activity_date]
    params[:activity][:activity_date] = Date.strptime(date, "%m/%d/%y")
    @activity = Activity.find(params[:id])
    if @activity.update_attributes(activity_params)
      redirect_to reports_path(:family_id => @activity.family_id)
    else
      render 'edit'
    end
  end

  def reports
    if params[:family_id]
      @selected_family = Family.find(params[:family_id])
      @activities = @selected_family.activities.paginate(page: params[:page], :per_page => 7)
    elsif params[:activity_date]
      @report_date = params[:activity_date]
      @activities = Activity.where("activity_date > ?", @report_date).joins(:family).where(
                                    :families => {:archived => false}).paginate(page: params[:page], :per_page => 10)
    else
      @activities = Activity.joins(:family).where(:families => {:archived => false}).paginate(page: params[:page], :per_page => 10)
    end
    @families = Family.where("archived = ?", false)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
  end

  def archive
    if params[:archive_family]
      archive_family = Family.find(params[:archive_family])
      archive_family.name = ward_decryptor.decrypt_and_verify(archive_family.name)
      archive_family.email = ward_decryptor.decrypt_and_verify(archive_family.email) if !archive_family.email.nil? && archive_family.email != ""
      archive_family.phone = ward_decryptor.decrypt_and_verify(archive_family.phone) if !archive_family.phone.nil? && archive_family.phone != ""
      archive_family.address = ward_decryptor.decrypt_and_verify(archive_family.address) if !archive_family.address.nil? && archive_family.address != ""
      archive_family.children = ward_decryptor.decrypt_and_verify(archive_family.children) if !archive_family.children.nil? && archive_family.children != ""
      archive_family.encrypted_password = cookies[:ward_password]
      archive_family.archived = true
      archive_family.save
    elsif params[:unarchive_id]
      unarchive_family = Family.find(params[:unarchive_id])
      unarchive_family.name = ward_decryptor.decrypt_and_verify(unarchive_family.name)
      unarchive_family.email = ward_decryptor.decrypt_and_verify(unarchive_family.email) if !unarchive_family.email.nil? && unarchive_family.email != ""
      unarchive_family.phone = ward_decryptor.decrypt_and_verify(unarchive_family.phone) if !unarchive_family.phone.nil? && unarchive_family.phone != ""
      unarchive_family.address = ward_decryptor.decrypt_and_verify(unarchive_family.address) if !unarchive_family.address.nil? && unarchive_family.address != ""
      unarchive_family.children = ward_decryptor.decrypt_and_verify(unarchive_family.children) if !unarchive_family.children.nil? && unarchive_family.children != ""
      unarchive_family.encrypted_password = cookies[:ward_password]
      unarchive_family.archived = false
      unarchive_family.save
    end
    @families = Family.where("archived = ?", true)
    @families.each do |family|
      family.encrypted_password = cookies[:ward_password]
    end
    if params[:family_id]
      @selected_family = Family.find(params[:family_id])
      @activities = @selected_family.activities
    end
  end

  private

    def activity_params
      params.require(:activity).permit(:family_id, :user_id, :activity_date, :notes, :reported_by, :visit)
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

end
