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

require 'spec_helper'

describe User do
  pending "add some examples to (or delete) #{__FILE__}"
end
