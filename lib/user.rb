require 'digest/sha1'
class User < ActiveRecord::Base
  include ActsAsRoled
  has_and_belongs_to_many :roles
  attr_accessor :roles_attributes
  attr_accessible :roles_attributes
  after_update :save_roles

  # authorized_as? simply needs to return true or false whether a user has a role or not.  
  # It may be a good idea to have "admin" roles return true always
  def authorized_as?(role_name)
    return true if role_names.include?("admin")
    has_role?(role_name)
  end

  def has_role?(role_name)
    role_names.include? role_name.to_s
  end

  def roles_to_sentence
    role_names.to_sentence
  end

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password, :normalize_open_id
  
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :open_id

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end
  
  # Authenticates a user by their open id indentifier.  Returns the user or nil.
  def self.open_id_authentication(identity_url)
    u = find_by_open_id(identity_url) # need to get the salt
    u ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  protected
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def normalize_open_id
    self.open_id = OpenIdAuthentication.normalize_url(open_id) unless open_id.blank?
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
    
  def role_names
    @role_names ||= self.roles.map(&:name)
  end
    
  def save_roles
    return if roles_attributes.nil?
    self.roles = Role.find_by_names(roles_attributes)
  end
end
