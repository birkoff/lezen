class Feed < ActiveRecord::Base
  attr_accessible :name, :url
  #has_many :readlater
  def self.get_user_feeds(user_id, full=true)
    if full then
      return Feed.where("user_id = ?", user_id).order("id ASC")
    else
      return Feed.select("id").where("user_id = ?", user_id).order("id ASC").map {|x| x.id}
    end
  end
end
