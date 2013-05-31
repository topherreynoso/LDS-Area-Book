# == Schema Information
#
# Table name: families
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  phone            :string(255)
#  email            :string(255)
#  address          :string(255)
#  children         :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  investigator     :boolean          default(FALSE)
#  watched          :boolean          default(FALSE)
#  archived         :boolean          default(FALSE)
#  confirmed_change :boolean          default(FALSE)
#

require 'spec_helper'

describe Family do
  pending "add some examples to (or delete) #{__FILE__}"
end
