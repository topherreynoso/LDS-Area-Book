class WardsController < ApplicationController
  before_action :signed_in_user, only: [:new, :leaders, :confirm, :create, :edit, :update]
  before_action :master_user, only: [:index, :destroy, :switch]

  def index
    @wards = Ward.paginate(page: params[:page])
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
    @unit_number = records_page.search('#heading-unit-number').first.text.to_s
    ward = records_page.search('#heading-unit-name').first.text.to_s
    @ward_name = ward[0..-5]
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

  private

    def ward_params
      params.require(:ward).permit(:name, :unit)
    end

    def signed_in_user
      redirect_to root_path unless signed_in?
    end

    def master_user
      redirect_to root_path unless signed_in? && current_user.master
    end
end
