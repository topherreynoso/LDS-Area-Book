# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  email           :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean          default(FALSE)
#  email_confirmed :boolean          default(FALSE)
#  master          :boolean          default(FALSE)
#  ward_id         :integer
#  ward_confirmed  :boolean          default(FALSE)
#  auth_code       :string(255)
#

class User < ActiveRecord::Base
  # allow master users and admins to skip validation so that they can accept or reject user requests for ward access
  attr_accessor :skip_validation

  # make sure that each user belongs to just one ward
  belongs_to :ward

  # make sure that all email addresses are lowercase and that each user has a unique remember token
  before_save { self.email = email.downcase }
  before_save :create_remember_token

  # make sure that each user has a name and a valid and unique email address
  validates :name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }

  # make sure that the password is confirmed and at least six characters in length
  has_secure_password
  validates :password_confirmation, presence: true, :unless => :skip_validation
  validates :password, length: { minimum: 6 }, :unless => :skip_validation

  # verify if the user changed their email address
  after_update :verify_email_after_change

  # sort users alphabetically
  default_scope order: 'name ASC'

  def verify_email_after_change
    # if the user email changed then send out a verification email
    if (self.email_changed?)
      UserMailer.user_email_verification(self.id).deliver
    end      
  end
  
  private

    def create_remember_token
      # create a random remember token for each user before saving
      self.remember_token = SecureRandom.urlsafe_base64
    end
end
