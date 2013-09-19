class UserLog < ActiveRecord::Base
  # attr_accessible :title, :body
  def self.add_action(action)
    @user_log = Userlog.new
    @user_log.ip_address = request.remote_ip
    @user_log.user_id = session[:user_id] or @user_log.user_id = nil
    @user_log.action = action
    @user_log.save
    return true
  end
end
