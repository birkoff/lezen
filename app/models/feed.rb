class Feed < ActiveRecord::Base
  attr_accessible :name, :url
  #has_many :readlater
end