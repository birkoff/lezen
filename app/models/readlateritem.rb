class Readlateritem < ActiveRecord::Base
  attr_accessible :feed_id, :url, :title, :date_published
  #belongs_to :feed
end
