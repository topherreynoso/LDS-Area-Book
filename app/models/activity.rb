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
  # make sure that each activity belongs to one family
  belongs_to :family
  
  # make sure that each activity has a family, a creator, a date, some note, and an indication of who reported it
  validates :family_id,  presence: true
  validates :user_id, presence: true
  validates :activity_date, presence: true
  validates :notes, presence: true, length: { maximum: 250 }
  validates :reported_by, presence: true, length: { maximum: 100 }

  # sort activities by most recent date
  default_scope order: 'activity_date DESC'
end
