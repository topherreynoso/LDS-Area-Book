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

  def self.import(file)
    import_families = []
    all_family_names = []
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
      family = Family.find_by_name(new_info["name"])
      if family.nil?
        family = Family.new
        family.name = new_info["name"]
        family.address = new_info["address"]
        family.phone = new_info["phone"]
        family.email = new_info["email"]
        family.children = new_info["children"]
        import_families << family
      else
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
    remove_families = Family.where("name NOT IN (?) and archived = ? and investigator = ?", all_family_names, false, false)
    remove_families.each do |family|
      import_families << family
    end
    return import_families
  end

end

