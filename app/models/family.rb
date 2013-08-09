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
  # add an encrypted_password field so that family records can be encrypted upon being saved or updated
  # this is a virtual attribute and is never saved on the database, it is set and lost with each user session
  attr_accessor :encrypted_password

  # make sure that each family can have many activities (which are destroyed with the family) and at least a name
  has_many :activities, dependent: :destroy
  validates :name,  presence: true

  # encrypt sensitive data before saving to the database
  before_save :encrypt_data

  # order families alphabetically
  default_scope order: 'name ASC'

  def decrypted_name
    # return the decrypted name of a family as long as an encrypted password exists from this session
    ActiveSupport::MessageEncryptor.new(encrypted_password).decrypt_and_verify(name)
  end

  def self.import(file, encrypted_password)
    # import families and data from a csv
    import_families = []
    all_family_names = []

    # use the encrypted password from this session to create the decryptor for sensitive family data
    ward_decryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)

    # go through the csv line by line in order to find any differences between the csv and the family database
    CSV.foreach(file.path, headers: true) do |row|

      # make sure that the first header column is "Family Name"
      return false if row.headers[0] != "Family Name"

      # set all family data to nil, we will fill it in as we determine which data we should use
      new_info = { "name" => nil, "phone" => nil, "email" => nil, "address" => nil, "children" => nil }
      
      # always use the "Couple Name" column for the name of the family and add this family's name to the array of all names
      new_info["name"] = row["Couple Name"]
      all_family_names << new_info["name"]

      # use the "Family Address" column as long as it is not empty
      new_info["address"] = row["Family Address"] if !row["Family Address"].nil? && row["Family Address"] != ""

      # use the "Family Phone" column as long as it is not empty
      new_info["phone"] = row["Family Phone"] if !row["Family Phone"].nil? && row["Family Phone"] != ""

      # if phone is still empty, use the "Head of House Phone" column
      if new_info["phone"].nil? 
        new_info["phone"] = row["Head Of House Phone"] if !row["Head Of House Phone"].nil? && row["Head Of House Phone"] != ""
      end

      # if phone is still empty, use the "Spouse Phone" column
      if new_info["phone"].nil?
        new_info["phone"] = row["Spouse Phone"] if !row["Spouse Phone"].nil? && row["Spouse Phone"] != ""
      end

      # use the "Family Email" column as long as it is not empty
      new_info["email"] = row["Family Email"] if !row["Family Email"].nil? && row["Family Email"] != ""
      
      # if email is still empty, use the "Head of House Email" column
      if new_info["email"].nil? 
        new_info["email"] = row["Head Of House Email"] if !row["Head Of House Email"].nil? && row["Head Of House Email"] != ""
      end

      # if email is still empty, use the "Spouse Email" column
      if new_info["email"].nil?
        new_info["email"] = row["Spouse Email"] if !row["Spouse Email"].nil? && row["Spouse Email"] != ""
      end

      # if at least one child's name is listed, start the children
      if !row[11].nil? && row[11] != ""
        children = row[11]
        i = 14

        # go three columns over and look for the next child, adding it to children, until there are no more children names listed
        loop do
          break if i > 56
          children += ", #{row[i]}" if !row[i].nil? && row[i] != ""
          i += 3
        end
        new_info["children"] = children
      end

      # look for a family in the database with the same name as this row
      family = nil
      Family.all.each do |found_family|
        found_family.encrypted_password = encrypted_password
        family = found_family if found_family.decrypted_name == new_info["name"]
      end

      # if no family exists with the same name, create a new record with the imported information and add it to the list of families to import
      if family.nil?
        family = Family.new
        family.name = new_info["name"]
        family.address = new_info["address"]
        family.phone = new_info["phone"]
        family.email = new_info["email"]
        family.children = new_info["children"]
        import_families << family

      # if a family does exist, decrypt current info, add imported info where different, and add it to the list of families to import
      else
        family.name = ward_decryptor.decrypt_and_verify(family.name)
        family.email = ward_decryptor.decrypt_and_verify(family.email) if !family.email.nil? && family.email != ""
        family.phone = ward_decryptor.decrypt_and_verify(family.phone) if !family.phone.nil? && family.phone != ""
        family.address = ward_decryptor.decrypt_and_verify(family.address) if !family.address.nil? && family.address != ""
        family.children = ward_decryptor.decrypt_and_verify(family.children) if !family.children.nil? && family.children != ""
        change_occurred = false
        if !(family.address == "" && new_info["address"].nil?) && !(family.address.nil? && new_info["address"] = "")
          if family.address != new_info["address"]
            family.address = new_info["address"]
            change_occurred = true
          end
        end
        if !(family.phone == "" && new_info["phone"].nil?) && !(family.phone.nil? && new_info["phone"] = "")
          if family.phone != new_info["phone"]
            family.phone = new_info["phone"]
            change_occurred = true
          end
        end
        if !(family.email == "" && new_info["email"].nil?) && !(family.email.nil? && new_info["email"] = "")
          if family.email != new_info["email"]
            family.email = new_info["email"]
            change_occurred = true
          end
        end
        if !(family.children == "" && new_info["children"].nil?) && !(family.children.nil? && new_info["children"] = "")
          if family.children != new_info["children"]
            family.children = new_info["children"]
            change_occurred = true
          end
        end
        if family.archived == true
          family.archived = false
          change_occurred = true
        end
        import_families << family if change_occurred
      end
    end

    # for each family currently in the ward, determine if the family exists in the csv, if it does not, add it to the list of families to archive
    Family.where("investigator = ? and archived = ?", false, false).each do |family|
      family.encrypted_password = encrypted_password
      import_families << family if !all_family_names.include? family.decrypted_name
    end

    # return an array of all families that need to be added, archived, or updated
    return import_families
  end

  private
    def encrypt_data
      # before saving any family, make sure that all of its sensitive information is encrypted using the session's encrypted password
      encryptor = ActiveSupport::MessageEncryptor.new(encrypted_password)
      self.name = encryptor.encrypt_and_sign(name)
      self.phone = encryptor.encrypt_and_sign(phone)
      self.email = encryptor.encrypt_and_sign(email)
      self.address = encryptor.encrypt_and_sign(address)
      self.children = encryptor.encrypt_and_sign(children)
    end

end