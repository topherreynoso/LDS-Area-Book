class WardsController < ApplicationController
  def index
    @wards = Ward.paginate(page: params[:page])
  end

  def new
  	@ward = Ward.new
  end

  def create
    @ward = Ward.new(ward_params)
    if @ward.save
      Apartment::Database.create(@ward.unit)
      redirect_to wards_path
    else
      render 'new'
    end
  end

  def destroy
    ward = Ward.find(params[:id])
    ward.users.each do |user|
      user.destroy if !user.master?
    end
    Apartment::Database.drop(ward.unit)
    set_ward nil if ward == current_ward
    ward.destroy
    redirect_to wards_path
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

  private

    def ward_params
      params.require(:ward).permit(:name, :unit)
    end
end
