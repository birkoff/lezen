class FeedsHandler
  MAX_FEED_ITEMS = 30
    
  def self.fetch_feed(feed, cache)
      feed_url = feed.url
          
      if cache == true then
          cache_file = feed_url.gsub(/[^a-zA-Z0-9 ]/, '_') 
          cache_file = "cache/#{cache_file}.xml"
          
          Rails.logger.debug "Getting feed cache" if $DEBUG == true
          Rails.logger.debug "cache file: #{cache_file}" if $DEBUG == true
          
          begin
            file_cache = FileCache.new(feed.url, cache_file, $update_interval)
            content = file_cache.get_api_cache
                    
            start_time = Time.now
          
            f = SimpleRSS.parse(content)
          rescue Exception => e
            return nil
          end
      else
          start_time = Time.now
          Rails.logger.debug "Getting feed without cache" if $DEBUG == true
          begin
            f = Feedzirra::Feed.fetch_and_parse(feed.url)
          rescue Exception => e
            return nil
          end
      end
      
      
      end_time = Time.now
      transaction_time = (end_time - start_time)
      Rails.logger.debug "Transaction Time (Feedzirra::Feed.parse) #{transaction_time} - #{feed.name}" if $DEBUG == true
      
      return f
  end
  
  def self.update_front_page_cache(feed_id, user_id)
    Rails.logger.debug "UPDATE FRONT PAGE CACHE..." if $DEBUG == true
    
    if feed_id.nil? then
        @feeds = Feed.get_user_feeds()
    else
        @feeds = Array.new(1) { Hash.new }
        @feeds[0] = Feed.find(feed_id)
    end
    
    #@feeds = Feed.get_user_feeds()
    
    #Item.delete_user_items()
    #Currentfeed = Struct.new(:feed_url, :feed_title, :title, :url, :published, :user_id)
    @mem_feeds = Array.new()
    
    i = 0
    x = 0
    @feeds.each do |feed|
        Rails.logger.debug "################################" if $DEBUG == true
        Rails.logger.debug "################################" if $DEBUG == true
        
        f = fetch_feed(feed, false)
        
        if f.nil?
           next 
        end

        feed_url = get_url(f)
        feed_title = f.title
     
        Rails.logger.debug "feed_url: #{feed_url}" if $DEBUG == true
        Rails.logger.debug "feed_title: #{feed_title}" if $DEBUG == true
        j=0
        f.entries.each do |item|
            title = item.title + " - " + feed_title
            url = get_url(item)
            #Rails.logger.debug "Item URL #{url}" if $DEBUG == true
            #Rails.logger.debug "item url: #{item.url}" if $DEBUG == true
            #Rails.logger.debug "link: #{item.link}" if $DEBUG == true
            
            published = get_date(item)
            summary   = item.summary
            #p = published.split(" ")
            #published = "#{p[-1]}-#{p[1]}-#{p[2]}"
            #Rails.logger.debug "published #{published}" if $DEBUG == true
            a=Date.parse(published)
            b=Date.today
            
            Rails.logger.debug "title: #{title}" if $DEBUG == true
            Rails.logger.debug "item published  #{published}" if $DEBUG == true
            Rails.logger.debug "Break if: #{a} < #{b}" if $DEBUG == true
            #Rails.logger.debug "url: #{url}" if DEBUG == true
            #Rails.logger.debug "published: #{published}" if DEBUG == true
            #Rails.logger.debug "item.dc_date.to_s: #{item.dc_date.to_s}" if DEBUG == true
            #Rails.logger.debug "item.pubDate.to_s #{item.pubDate.to_s}" if DEBUG == true
            j=j+1
            break if a < b or j > 4 #Break if: 2013-08-30 < 2013-08-30 or already 4 items from that feed
            
            #Currentfeed.new(feed_url, feed_title, title, url, published, 1)
            
            #Rails.logger.debug "Memfeeds: #{@mem_feeds.inspect}" if $DEBUG == true
            
            @item = Item.new
            @item.feed_url = feed_url
            @item.feed_title = feed_title
            @item.title = title
            @item.url = url
            @item.published = published
            @item.user_id = user_id
            @item.save
            
            @mem_feeds[x] = @item
            x = x + 1   
        end
        i+=1 unless @mem_feeds[i].nil?
        break if i>=MAX_FEED_ITEMS
     end
     self.update_cache_status_file($cache_status_file,Time.new.to_s)
     return @mem_feeds
  end
  
  def self.get_url(_feed)
    #Rails.logger.debug "Item URL #{url}" if $DEBUG == true
    #Rails.logger.debug "item url: #{feed.url}" if $DEBUG == true
    #Rails.logger.debug "Item link: #{_feed.link}" if $DEBUG == true
            
    #Rails.logger.debug "if url blank: #{(defined? _feed.url).blank?}"
    #Rails.logger.debug "if url nil #{(defined? _feed.url).nil?}"
    #Rails.logger.debug "if link blank: #{(defined? _feed.link).blank?}"
    #Rails.logger.debug "if link nil: #{(defined? _feed.link).nil?}"
    return _feed.url
    #if defined? ur.link
    #  url = _feed.link
    #elsif defined? feed.url
    #  url = _feed.url
    #else 
    
    #  url = ''
    #end
    #Rails.logger.debug "Return URL: #{url}"
    #return url
  end
  
  def self.get_date(feed)
    #if feed.dc_date
    #  published = feed.dc_date.to_s
    #elsif  feed.pubDate
    #  published = feed.pubDate.to_s
    #elsif feed.published
    #  published = feed.published.to_s
    #else 
    #  published = ''
    #end
    return feed.published.to_s
  end
  
  def self.update_cache_status_file(cache_file, content)
     Rails.logger.debug "Updating cache status file... #{cache_file}"  if $DEBUG == true 
     fp = File.new(cache_file, 'w') # open as new file to reset date
     if fp
       #acquire an exclusive lock (writer)
       if fp.flock(File::LOCK_EX)
         #content = a=Time.new.to_s
         fp.write(content)  # writes to the file
         fp.flock(File::LOCK_UN) # release a lock
       end
       fp.close
     end
   end
   
   def self.cache_needs_update(cache_file, update_interval)
      update_interval = update_interval * 60
      Rails.logger.debug "Cache Needs update?..." if $DEBUG == true
      if File.exist?(cache_file) then
        b=File.ctime(cache_file).to_i
      else
        b=0
      end
      a=Time.new.to_i
      c=a-b
      Rails.logger.debug "#{!File.exist?(cache_file)} or #{c} #{2500}" if $DEBUG == true
      if !File.exist?(cache_file) or c > update_interval
          Rails.logger.debug "Cache file needs update... true" if $DEBUG == true
          return true
      else
          Rails.logger.debug "Cache file needs update... false" if $DEBUG == true
          return false
      end
  end
end