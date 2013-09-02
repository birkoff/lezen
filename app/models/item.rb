class Item < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.get_user_items
    return Item.where("user_id = ?", 1).order("id ASC")
  end
  
  def self.delete_user_items
    Item.where(:user_id => 1).destroy_all
  end
end
