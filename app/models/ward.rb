# == Schema Information
#
# Table name: wards
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  unit       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  ward_token :string(255)
#  confirm    :string(255)
#

class Ward < ActiveRecord::Base
  # create a confirmation ward password as a virtual attribute since this is never stored in the database
  attr_accessor :confirm_again
  has_many :users

  # get a ward token so that a user's ward can be quickly retrieved with a cookie
  before_save :create_ward_token

  # makes sure that each ward has a name and selected a password, do not store the password, instead use an encrypted string that we know
  # the decrypted result of in order to facilitate verification that the user has entered the ward password correctly
  validates :name, presence: true
  validates :confirm, presence: true, length: { minimum: 5 }
  VALID_UNIT_REGEX = /\A[a-zA-Z\d]*\z/i
  validates :unit, presence: true, format: { with: VALID_UNIT_REGEX }, length: { minimum: 5, maximum: 10 }, uniqueness: true

  # order wards alphabetically
  default_scope order: 'name ASC'

  private

    def create_ward_token
      self.ward_token = SecureRandom.urlsafe_base64
    end
end
