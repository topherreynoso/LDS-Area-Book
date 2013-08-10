class UserMailer < ActionMailer::Base
  default from: "support@ldsareabook.org"

  def user_email_verification(user_id)
  	@user = User.find(user_id)
  	mail(:to => @user.email, :subject => "LDS Area Book - Verify Your Email", :content_type => "text/html")
  end

end
