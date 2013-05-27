# == Schema Information
#
# Table name: activities
#
#  id            :integer          not null, primary key
#  family_id     :integer
#  user_id       :integer
#  activity_date :date
#  notes         :string(255)
#  reported_by   :string(255)
#  visit         :boolean          default(FALSE)
#  created_at    :datetime
#  updated_at    :datetime
#

class Activity < ActiveRecord::Base
  belongs_to :family
  
  validates :family_id,  presence: true
  validates :user_id, presence: true
  validates :activity_date, presence: true
  validates :notes, presence: true, length: { maximum: 250 }
  validates :reported_by, presence: true, length: { maximum: 100 }

  default_scope order: 'activity_date DESC'
end
