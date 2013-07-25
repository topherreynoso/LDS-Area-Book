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
#  email_confirmed :boolean          default(TRUE)
#  master          :boolean          default(FALSE)
#  ward_id         :integer
#  ward_confirmed  :boolean          default(FALSE)
#

class User < ActiveRecord::Base
  attr_accessor :skip_validation
  belongs_to :ward

  before_save { self.email = email.downcase }
  before_save :create_remember_token

  validates :name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }

  has_secure_password
  validates :password_confirmation, presence: true, :unless => :skip_validation
  validates :password, length: { minimum: 6 }, :unless => :skip_validation

  default_scope order: 'name ASC'

  private

    def create_remember_token
      self.remember_token = SecureRandom.urlsafe_base64
    end
end
