module SessionsHelper

  def sign_in(user)
    # create a cookie with the user's remember token and make this the current_user
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user

    # if the user is confirmed in a ward and their email is confirmed, set the current ward to their confirmed ward
    if !user.ward_id.nil? && user.ward_confirmed && user.email_confirmed
      ward = Ward.find(user.ward_id)
      set_ward ward
    end
  end

  def signed_in?
    # is there a user logged in
    !current_user.nil?
  end

  def current_user=(user)
    # set the current user
    @current_user = user
  end

  def current_user
    # return the current user or retrieve it from the cookie
    @current_user ||= User.find_by(remember_token: cookies[:remember_token])
  end

  def current_user?(user)
    # determine if the current user is the same as the user
    user == current_user
  end

  def sign_out
    # make sure the current user, current ward, and ward decryptor are all destroyed, ending this session
    self.current_user = nil
    self.current_ward = nil
    self.ward_decryptor = nil
    cookies.delete(:remember_token)
    cookies.delete(:ward_token)
    cookies.delete(:ward_password)
  end

  def redirect_back_or(default)
    # redirect to the location before the sign in request occurred
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    # hold on to the location in order to complete the sign in request
    session[:return_to] = request.url
  end

  def set_ward(ward)
    # if a ward is selected, save the ward token as a cookie, switch to the proper ward database, and set the current ward
    if !ward.nil?
      if ward.id == current_user.ward_id || current_user.master?
        cookies.permanent[:ward_token] = ward.ward_token
        Apartment::Database.switch(ward.unit)
        self.current_ward = ward
      end

    # otherwise destroy the cookie, set the current ward to nil, and exit the ward database
    else
      cookies.permanent[:ward_token] = nil
      Apartment::Database.switch()
      self.current_ward = nil
    end
  end

  def current_ward=(ward)
    # set the current ward
    @current_ward = ward
  end

  def current_ward
    # retrieve the current ward or use the cookie to find it
    @current_ward ||= Ward.find_by(ward_token: cookies[:ward_token])
  end

  def current_ward?
    # determine if there is a current ward
    !current_ward.nil?
  end

  def set_ward_password(password)
    # if a password has been submitted, encrypt it, make a cookie with the encrypted version, and set the ward decryptor using the password
    if !password.nil?
      encrypted_password = OpenSSL::Digest::SHA256.new(password).digest
      cookies.permanent[:ward_password] = encrypted_password
      self.ward_decryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)
    
    # otherwise destroy the cookie and the ward decryptor
    else
      cookies.permanent[:ward_password] = nil
      self.ward_decryptor = nil
    end
  end

  def ward_decryptor=(encoder)
    # set the ward decryptor for this session
    @ward_decryptor = encoder
  end

  def ward_decryptor
    # return the ward decryptor or create a new one from the cookie
    if !@ward_decryptor.nil?
      @ward_decryptor
    elsif !cookies[:ward_password].nil?
      ActiveSupport::MessageEncryptor.new(cookies[:ward_password])
    else
      nil
    end
  end

  def ward_decryptor_valid?
    # determine if the ward decryptor is still valid
    if !ward_decryptor.nil? && ward_decryptor.decrypt_and_verify(current_ward.confirm) == current_ward.unit
      true
    else
      false
    end
    
  # if the ward decryptor is not valid, let the user know that they need to reenter the ward password
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

end
