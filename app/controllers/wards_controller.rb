class WardsController < ApplicationController
  before_action :signed_in_user, only: [:leaders, :confirm, :create, :edit, :update]
  before_action :master_user, only: [:new, :index, :destroy, :switch]

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
      redirect_to root_path, notice: 'Please sign in to access this area.' unless signed_in?
    end

    def master_user
      redirect_to root_path, notice: 'You do not have permission to access this area.' unless signed_in? && current_user.master
    end
end
