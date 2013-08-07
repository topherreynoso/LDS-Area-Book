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

class Family < ActiveRecord::Base
  attr_accessor :encrypted_password
  has_many :activities, dependent: :destroy
  validates :name,  presence: true
  before_save :encrypt_data

  default_scope order: 'name ASC'

  def decrypted_name
    ActiveSupport::MessageEncryptor.new(encrypted_password).decrypt_and_verify(name)
  end

  def self.import(file, encrypted_password)
    import_families = []
    all_family_names = []
    ward_decryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)
    CSV.foreach(file.path, headers: true) do |row|
      return false if row.headers[0] != "Family Name"
      new_info = { "name" => nil, "phone" => nil, "email" => nil, "address" => nil, "children" => nil }
      new_info["name"] = row["Couple Name"]
      all_family_names << new_info["name"]
      new_info["address"] = row["Family Address"] if !row["Family Address"].nil? && row["Family Address"] != ""
      new_info["phone"] = row["Family Phone"] if !row["Family Phone"].nil? && row["Family Phone"] != ""
      if new_info["phone"].nil? 
        new_info["phone"] = row["Head Of House Phone"] if !row["Head Of House Phone"].nil? && row["Head Of House Phone"] != ""
      end
      if new_info["phone"].nil?
        new_info["phone"] = row["Spouse Phone"] if !row["Spouse Phone"].nil? && row["Spouse Phone"] != ""
      end
      new_info["email"] = row["Family Email"] if !row["Family Email"].nil? && row["Family Email"] != ""
      if new_info["email"].nil? 
        new_info["email"] = row["Head Of House Email"] if !row["Head Of House Email"].nil? && row["Head Of House Email"] != ""
      end
      if new_info["email"].nil?
        new_info["email"] = row["Spouse Email"] if !row["Spouse Email"].nil? && row["Spouse Email"] != ""
      end
      if !row[11].nil? && row[11] != ""
        children = row[11]
        i = 14
        loop do
          break if i > 56
          children += ", #{row[i]}" if !row[i].nil? && row[i] != ""
          i += 3
        end
        new_info["children"] = children
      end
      family = nil
      Family.all.each do |found_family|
        found_family.encrypted_password = encrypted_password
        family = found_family if found_family.decrypted_name == new_info["name"]
      end
      if family.nil?
        family = Family.new
        family.name = new_info["name"]
        family.address = new_info["address"]
        family.phone = new_info["phone"]
        family.email = new_info["email"]
        family.children = new_info["children"]
        import_families << family
      else
        family.name = ward_decryptor.decrypt_and_verify(family.name)
        family.email = ward_decryptor.decrypt_and_verify(family.email) if !family.email.nil? && family.email != ""
        family.phone = ward_decryptor.decrypt_and_verify(family.phone) if !family.phone.nil? && family.phone != ""
        family.address = ward_decryptor.decrypt_and_verify(family.address) if !family.address.nil? && family.address != ""
        family.children = ward_decryptor.decrypt_and_verify(family.children) if !family.children.nil? && family.children != ""
        if !(family.address == "" && new_info["address"].nil?) && !(family.address.nil? && new_info["address"] = "")
          family.address = new_info["address"] if family.address != new_info["address"]
        end
        if !(family.phone == "" && new_info["phone"].nil?) && !(family.phone.nil? && new_info["phone"] = "")
          family.phone = new_info["phone"] if family.phone != new_info["phone"]
        end
        if !(family.email == "" && new_info["email"].nil?) && !(family.email.nil? && new_info["email"] = "")
          family.email = new_info["email"] if family.email != new_info["email"]
        end
        if !(family.children == "" && new_info["children"].nil?) && !(family.children.nil? && new_info["children"] = "")
          family.children = new_info["children"] if family.children != new_info["children"]
        end
        family.archived = false if family.archived == true
        import_families << family if family.changed?
      end
    end
    Family.all.each do |family|
      family.encrypted_password = encrypted_password
      import_families << family if !all_family_names.include? family.decrypted_name
    end
    return import_families
  end

  private
    def encrypt_data
      encryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)
      self.name = encryptor.encrypt_and_sign(name)
      self.phone = encryptor.encrypt_and_sign(phone)
      self.email = encryptor.encrypt_and_sign(email)
      self.address = encryptor.encrypt_and_sign(address)
      self.children = encryptor.encrypt_and_sign(children)
    end

end