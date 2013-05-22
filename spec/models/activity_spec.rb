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

require 'spec_helper'

describe Activity do
  pending "add some examples to (or delete) #{__FILE__}"
end
