# == Schema Information
#
# Table name: families
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  phone        :string(255)
#  email        :string(255)
#  address      :string(255)
#  children     :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  investigator :boolean          default(FALSE)
#  watched      :boolean          default(FALSE)
#  archived     :boolean          default(FALSE)
#

class Family < ActiveRecord::Base
  before_save { 
  	if self.email?
  	  self.email = email.downcase
  	end 
  }

  has_many :activities, dependent: :destroy

  validates :name,  presence: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, format: { with: VALID_EMAIL_REGEX }, :if => :email?

  default_scope order: 'name ASC'
 end

