class Feed < ActiveRecord::Base
  attr_accessible :name, :url
  #has_many :readlater
  def self.get_user_feeds
    return Feed.where("user_id = ?", 1).order("id ASC")
  end
end
