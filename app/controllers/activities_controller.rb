class ActivitiesController < ApplicationController
  before_action :authorized_user, only: [:edit, :new, :update, :create, :destroy, :reports, :archive]

  def new
  	@activity = Activity.new
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
  end

  def archive
    if params[:archive_family]
      archive_family = Family.find(params[:archive_family])
      archive_family.archived = true
      archive_family.save
    elsif params[:unarchive_id]
      unarchive_family = Family.find(params[:unarchive_id])
      unarchive_family.archived = false
      unarchive_family.save
    end
    @families = Family.where("archived = ?", true)
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
      unless signed_in? && (current_ward || current_user.master)
        redirect_to root_path, notice: 'You do not have permission to access this area.'
      end
    end
end
