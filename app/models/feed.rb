class Feed < ActiveRecord::Base
  attr_accessible :name, :url, :user_id
  #has_many :readlater
  
  before_save do |record|
    unless self.unique then
      raise "Feed name or url already exists."
    end
    
    unless self.user_feed_quota(record.user_id) then
      raise "You cannot agregate more than 40 feeds."
    end
    
    return true
  end
  
  after_create do |record|
    #UserLog.add_action('add_feed')
    return true
  end
  
  def self.get_user_feeds(user_id, full=true)
    if full then
      return Feed.where("user_id = ?", user_id).order("id ASC")
    else
      return Feed.select("id").where("user_id = ?", user_id).order("id ASC").map {|x| x.id}
    end
  end
  
  def unique
    user_feeds = Feed.where("user_id = ? and (name = ? or url = ?)", self.user_id,  self.name, self.url).count
    if user_feeds > 0
      return false
    end
    return true
  end
  
  def user_feed_quota(user_id)
    user_feeds = Feed.where("user_id = ?", user_id).count
    if user_feeds > 40
      return false
    end
    return true
  end
end
