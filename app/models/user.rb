class User < ActiveRecord::Base
  # attr_accessible :title, :body
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :password
  
  #validates_uniqueness_of :email
  attr_accessible :email, :password
  
  before_save do |record|
    unless self.unique then
      raise "An user with that email already exist."
    end
    return true
  end
  
  after_create do |record|
    #UserLog.add_action('create_user')
    return true
  end
  
  def self.authenticate(email, password)
    find(:first, :conditions => ["email = ? and password = ?", "#{email}", "#{password}"])
  end
  
  def unique
    count = User.where("email = ?", self.email).count
    if count > 0
      return false
    end
    return true
  end
end
