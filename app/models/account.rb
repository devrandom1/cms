# class to manage user accounts on CMS.  Note that this class is different
# than the Person class, because not all people responsible for compliance will
# have an account.
class Account < ActiveRecord::Base
  include AuthoredModel
  attr_accessor :password, :password_confirmation

  before_save :encrypt_password
  before_save do
    reset_persistence_token if reset_persistence_token?
  end

  is_versioned_ext

  # Validations
  validates_presence_of      :email, :role
  validates_presence_of      :password,                          :if => :password_required
  validates_presence_of      :password_confirmation,             :if => :password_required
  validates_length_of        :password, :minimum => 4, :maximum => 40,   :if => :password_required
  validates_confirmation_of  :password,                          :if => :password_required
  validates_length_of        :email,    :minimum => 3, :maximum => 100
  validates_uniqueness_of    :email,    :case_sensitive => false
  #validates_format_of        :email,    :with => :email_address
  validates_format_of        :role,     :with => /[A-Za-z]/

  def password=(password)
    @password = password
    encrypt_password
  end

  ##
  # This method is for authentication purpose
  #
  def self.authenticate(email, password)
    account = self.where(:email => email).first if email.present?
    account && account.has_password?(password) ? account : nil
  end

  ##
  # This method is used by AuthenticationHelper
  #
  def self.find_by_id(id)
    find(id) rescue nil
  end

  def valid_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  ##
  # These methods are for ActiveRecord compatibility to make the 
  # authlogic gem work
  #

  def display_name
    email
  end

  # TODO: Why was this here?  (Commented out on move to AR)
  #def self.column_names
  #  []
  #end

  #def self.with_scope(scope)
  #  raise "cannot handle scopes" if scope[:find] && scope[:find] != {}
  #  yield
  #end

  ##
  # Other authlogic configuration
  def self.login_field
    :email
  end

  # Breaks .create()
  #def self.primary_key
  #  :id
  #end

  def self.find_by_smart_case_login_field(value)
    self.where(:email => value).first
  end

  def self.find_by_persistence_token(value)
    where(:persistence_token => value).first
  end

  ##
  # End authlogic configuration
  #


  # For acl9 authorization
  def has_role?(role_name, obj=nil)
    self.role == role_name.to_s
  end

  def has_role!(role_name, obj=nil)
    self.role = role_name
    save!
  end

  def reset_persistence_token
    self.persistence_token = Authlogic::Random.hex_token
  end

  def reset_persistence_token!
    reset_persistence_token
    save!
  end

  def self.forget_all!
    records = nil
    i = 0
    begin
      records = self.limit(50).offset(i)
      records.each { |r| r.reset_persistence_token! }
      i += 50
    end while !records.blank?
  end

  private
    def reset_persistence_token?
      persistence_token.blank?
    end

    def password_required
      crypted_password.blank? || password.present?
    end

    def encrypt_password
      if password.present?
        self.crypted_password = ::BCrypt::Password.create(password)
        reset_persistence_token
      end
    end
end
