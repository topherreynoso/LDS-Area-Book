class UserMailer < ActionMailer::Base
  default from: "support@ldsareabook.org"

  def user_email_verification(user_id)
  	@user = User.find(user_id)
  	mail(:to => @user.email, :subject => "LDS Area Book - Verify Your Email", :content_type => "text/html")
  end

  def user_regain_access(user_id)
  	@user = User.find(user_id)
  	mail(:to => @user.email, :subject => "LDS Area Book - Regain Access", :content_type => "text/html")
  end

  def user_request_access(ward_id)
  	@admins = User.where(:ward_id => ward_id).where(:admin => true)
  	@admin_emails = ""
  	@admins.each do |admin|
  	  if @admin_emails == ""
  	 	@admin_emails = admin.email
  	  else
  	  	@admin_emails += ", #{admin.email}"
  	  end
  	end
  	mail(:to => @admin_emails, :subject => "A New User Requested Access", :content_type => "text/html")
  end

  def user_access_status(user_id)
    @user = User.find(user_id)
    mail(:to => @user.email, :subject => "Area Book Access Changed", :content_type => "text/html")
  end

  def user_email_admin(user_id, ward_id, message)
  	@user = User.find(user_id)
  	@admins = User.where(:ward_id => ward_id).where(:admin => true)
  	@admin_emails = ""
  	@admins.each do |admin|
  	  if @admin_emails == ""
  	 	@admin_emails = admin.email
  	  else
  	  	@admin_emails += ", #{admin.email}"
  	  end
  	end
  	@message = message
  	mail(:to => @admin_emails, :subject => "Message from #{@user.name}", :content_type => "text/html")
  end

end
