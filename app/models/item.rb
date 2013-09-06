class Item < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.get_user_items(user_id)
    return Item.where("user_id = ?", user_id).order("id ASC")
  end
  
  def self.delete_user_items(user_id)
    Item.where("user_id = ?", user_id).destroy_all
  end
end
