require 'digest/sha1'
class User < ActiveRecord::Base
  include Lockdown::Helper
  has_and_belongs_to_many :user_groups
  belongs_to :profile
  
  # Virtual attributes
  attr_accessor :password

  validates_presence_of     :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login, :case_sensitive => false
  
  validates_presence_of :profile
	validates_associated	:profile
  
	before_save :prepare_for_save

	after_create :assign_registered_users_user_group
  
  attr_accessible :login, :password, :password_confirmation
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find :first, :conditions => ['login = ?', login] # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

	def self.all
		find :all, :include => [:profile, :user_groups] 
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end
  
  def access_rights
    rvalue = Lockdown::UserGroups[:public_access]
    self.user_groups.each{|grp| rvalue += grp.access_rights}
    rvalue
  end

  def email
    self.profile.email
  end
  
  def full_name
    self.profile.first_name + " " + self.profile.last_name
  end
  
	def administrator?
		has_user_group? :administrators
  end

  def has_user_group?(sym)
    self.user_groups.each do |ug|
      return true if convert_reference_name(ug.name) == sym
    end
    false
  end

  protected
		def assign_registered_users_user_group
			self.user_groups << UserGroup.find_by_sym(:registered_users)
    end 

    def prepare_for_save
			encrypt_password
			self.profile.save
    end
      
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      (crypted_password.blank? || !password.blank?)
    end
    
end
