class ActivitiesController < ApplicationController
  def new
  	@activity = Activity.new
  end

  def create
  	@activity = Activity.new(activity_params)
  	@activity.user_id = current_user.id
  	family = Family.find(@activity.family_id)
    if @activity.save
      flash[:success] = "New activity reported for #{family.name}."
      if family.investigator?
      	redirect_to investigators_path
      else
      	redirect_to ward_path
      end
    else
      render 'new'
    end
  end

  def edit
    @activity = Activity.find(params[:id])
  end

  def update
    @activity = Activity.find(params[:id])
    family = Family.find(@activity.family_id)
    if @activity.update_attributes(activity_params)
      flash[:success] = "Activity information updated for #{family.name}."
      redirect_to reports_path(:family_id => family.id)
    else
      render 'edit'
    end
  end

  def reports
    @visit_count = 0
    if params[:family_id]
      @selected_family = Family.find(params[:family_id])
      @activities = @selected_family.activities
      @activities.each do |activity|
        if activity.visit?
          @visit_count += 1
        end
      end
    elsif params[:activity_date]
      @report_date = params[:activity_date]
      @activities = []
      all_activities = Activity.where("activity_date > ?", @report_date)
      all_activities.each do |activity|
        if !Family.find(activity.family_id).archived?
          @activities << activity
          if activity.visit?
            @visit_count += 1
          end
        end
      end
    else
      @activities = []
      Activity.all.each do |activity|
        if !Family.find(activity.family_id).archived?
          @activities << activity
          if activity.visit?
            @visit_count += 1
          end
        end
      end
    end
  end

  def archive
    if params[:archive_family]
      archive_family = Family.find(params[:archive_family])
      archive_family.archived = true
      if archive_family.save
        flash[:success] = "Successfully archived #{archive_family.name}."
      end
    elsif params[:unarchive_id]
      unarchive_family = Family.find(params[:unarchive_id])
      unarchive_family.archived = false
      if unarchive_family.save
        flash[:success] = "Successfully unarchived #{unarchive_family.name}."
      end
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

    def signed_in_user
      unless signed_in?
        store_location
        redirect_to signin_url, notice: "Please sign in."
      end
    end
end
