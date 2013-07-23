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
#

class Ward < ActiveRecord::Base
  has_many :users

  before_save :create_ward_token

  validates :name, presence: true
  validates :unit, presence: true, uniqueness: true

  default_scope order: 'name ASC'

  private

    def create_ward_token
      self.ward_token = SecureRandom.urlsafe_base64
    end
end
