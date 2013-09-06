class User < ActiveRecord::Base
  # attr_accessible :title, :body
  validates_presence_of :name
  validates_presence_of :email
  validates_presence_of :password
  
  validates_uniqueness_of :email
  attr_accessible :email, :password

  def self.authenticate(email, password)
    find(:first, :conditions => ["email = ? and password = ?", "#{email}", "#{password}"])
  end
end
