module SessionsHelper

  def sign_in(user)
    cookies.permanent[:remember_token] = user.remember_token
    self.current_user = user
    if !user.ward_id.nil? && user.ward_confirmed && !user.master? && user.email_confirmed
      ward = Ward.find(user.ward_id)
      set_ward ward
    elsif user.master?
      set_ward nil
    end
  end

  def signed_in?
    !current_user.nil?
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.find_by(remember_token: cookies[:remember_token])
  end

  def current_user?(user)
    user == current_user
  end

  def sign_out
    self.current_user = nil
    self.current_ward = nil
    self.ward_decryptor = nil
    cookies.delete(:remember_token)
    cookies.delete(:ward_token)
    cookies.delete(:ward_password)
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    session.delete(:return_to)
  end

  def store_location
    session[:return_to] = request.url
  end

  def set_ward(ward)
    if !ward.nil?
      if ward.id == current_user.ward_id || current_user.master?
        cookies.permanent[:ward_token] = ward.ward_token
        Apartment::Database.switch(ward.unit)
        self.current_ward = ward
      end
    else
      cookies.permanent[:ward_token] = nil
      Apartment::Database.switch()
      self.current_ward = nil
    end
  end

  def current_ward=(ward)
    @current_ward = ward
  end

  def current_ward
    @current_ward ||= Ward.find_by(ward_token: cookies[:ward_token])
  end

  def current_ward?
    !current_ward.nil?
  end

  def set_ward_password(password)
    if !password.nil?
      encrypted_password = OpenSSL::Digest::SHA256.new(password).digest
      cookies.permanent[:ward_password] = encrypted_password
      self.ward_decryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)
    else
      cookies.permanent[:ward_password] = nil
      self.ward_decryptor = nil
    end
  end

  def ward_decryptor=(encoder)
    @ward_decryptor = encoder
  end

  def ward_decryptor
    if !@ward_decryptor.nil?
      @ward_decryptor
    elsif !cookies[:ward_password].nil?
      ActiveSupport::MessageEncryptor.new(cookies[:ward_password])
    else
      nil
    end
  end

  def ward_decryptor_valid?
    if !ward_decryptor.nil? && ward_decryptor.decrypt_and_verify(current_ward.confirm) == current_ward.unit
      true
    else
      false
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to password_path, notice: 'Your ward password was not valid. Please re-enter your password.'
  end

end
