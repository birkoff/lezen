require 'rubygems'
require 'open-uri'
require 'feedzirra'
require 'feedbag'
require 'date'
require 'file_cache'
require 'simple-rss'

class FeedsController < ApplicationController
  #caches_page :index
  
  $DEBUG = true
  
  MAX_FEED_ITEMS = 30
  
  Currentfeed = Struct.new(:feed_url, :feed_title, :title, :url, :published, :summary)

  def index
    @feeds = Feed.order("id ASC")
  end
  
  def front_page
    @feeds = Feed.order("id ASC")
    @mem_feeds = Array.new()
    i = 0
    @feeds.each do |feed|
        f = fetch_feed(feed, true)
        if f.nil? : next end

        feed_url = get_url(f)
        feed_title = f.title
        
        logger.debug "feed_url: #{feed_url}" if $DEBUG == true
        logger.debug "feed_title: #{feed_title}" if $DEBUG == true
        #logger.debug "entries #{f.inspect}" if feed_title == 'La uno.com'
        
        j=0
        f.entries.each do |item|
            j=j+1
            title     = item.title + " - " + feed_title
            url = get_url(item)
            published = get_date(item)
            summary   = item.summary
            p = published.split(" ")
            published = "#{p[-1]}-#{p[1]}-#{p[2]}"
            logger.debug "item published  #{published}" if $DEBUG == true
            a=Date.parse(published)
            b=Date.today
            logger.debug "Break if: #{a} < #{b}" if $DEBUG == true
            break if a < b #a < b # Tue Jun 04 15:16:00 UTC 2013
            @mem_feeds[i] = Currentfeed.new(feed_url, feed_title, title, url, published, summary)
            
            #logger.debug "title: #{title}" if DEBUG == true
            #logger.debug "url: #{url}" if DEBUG == true
            #logger.debug "published: #{published}" if DEBUG == true
            #logger.debug "item.dc_date.to_s: #{item.dc_date.to_s}" if DEBUG == true
            #logger.debug "item.pubDate.to_s #{item.pubDate.to_s}" if DEBUG == true
            break
        end
        i+=1 unless @mem_feeds[i].nil?
        break if i>=MAX_FEED_ITEMS
     end
     #logger.debug "mem feeds #{@mem_feeds.inspect}" if $DEBUG == true
     render :partial => 'front_page'
  end
  
  def generate_index_feeds
    @feeds = Feed.order("id ASC")
    @mem_feeds = Array.new()
    i = 0
    @feeds.each do |feed|
        f = fetch_feed(feed, true)
        if f.nil? : next end

        feed_url = get_url(f)
        feed_title = f.title
        
        logger.debug "feed_url: #{feed_url}" if $DEBUG == true
        logger.debug "feed_title: #{feed_title}" if $DEBUG == true
        #logger.debug "entries #{f.inspect}" if feed_title == 'La uno.com'
        
        j=0
        f.entries.each do |item|
            j=j+1
            title     = item.title + " - " + feed_title
            url = get_url(item)
            published = get_date(item)
            summary   = item.summary
            p = published.split(" ")
            published = "#{p[-1]}-#{p[1]}-#{p[2]}"
            logger.debug "item published  #{published}" if $DEBUG == true
            a=Date.parse(published)
            b=Date.today
            logger.debug "Break if: #{a} < #{b}" if $DEBUG == true
            break if a < b #a < b # Tue Jun 04 15:16:00 UTC 2013
            @mem_feeds[i] = Currentfeed.new(feed_url, feed_title, title, url, published, summary)
            
            #logger.debug "title: #{title}" if DEBUG == true
            #logger.debug "url: #{url}" if DEBUG == true
            #logger.debug "published: #{published}" if DEBUG == true
            #logger.debug "item.dc_date.to_s: #{item.dc_date.to_s}" if DEBUG == true
            #logger.debug "item.pubDate.to_s #{item.pubDate.to_s}" if DEBUG == true
            break
        end
        i+=1 unless @mem_feeds[i].nil?
        break if i>=MAX_FEED_ITEMS
     end
     #logger.debug "mem feeds #{@mem_feeds.inspect}" if $DEBUG == true
     render :partial => 'front_page'
  end
  
  def show
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = fetch_feed(@feedobj, false)
    logger.debug "entries #{@feed.inspect}"
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
    render :partial => 'feed'
  end
  
  def show_feed_ajax
    id = params[:id].to_i
    @feedobj = Feed.find(params[:id])
    @feed = fetch_feed(@feedobj, false)
    logger.debug "entries #{@feed.inspect}"
    items = Readlateritem.where(["feed_id = ?", @feedobj.id]).select("title")
    @read_later_items = Array.new
    items.each do |i|
      @read_later_items << i.title
    end
    render :partial => 'feed'
  end
  
  def new
    @feed = Feed.new
  end
  
  def edit
    @feed = Feed.find(params[:id])
  end
  
  def update
    @feed = Feed.find(params[:id])
    @feed.update_attributes(params[:feed])
    flash[:notice] = "Feed Updated."
    redirect_to :action => 'index'
  end
  
  def create
    params[:feed][:url] = Feedbag.find(params[:feed][:url]).first
    unless params[:feed][:url].nil? or params[:feed][:name].blank? then
        @feed = Feed.new(params[:feed])
        @feed.save
        flash[:notice] = "Feed Created."
        redirect_to :action => 'index'
    else
        flash[:notice] = "Feed URL or Name not valid."
        redirect_to :action => 'new'
    end
  end
  
  def destroy
    Feed.find(params[:id]).destroy
    flash[:notice] = "Ambulancia Eliminada."
    redirect_to :action => 'index'
  end
  
  private
  def fetch_feed(feed, cache)
      feed_url = feed.url
          
      if cache == true then
          #logger.debug "Getting feed cache" if $DEBUG == true
          
          cache_file = feed_url.gsub(/[^a-zA-Z0-9 ]/, '_') 
          cache_file = "cache/#{cache_file}.xml"
          
          #logger.debug "cache file: #{cache_file}" if $DEBUG == true
    
          file_cache = FileCache.new(feed.url, cache_file, 10)
          content = file_cache.get_api_cache
                    
          start_time = Time.now
          begin
            f = SimpleRSS.parse(content)
            #logger.debug "Debug SimpleRSS.parse(content)" if $DEBUG == true
          rescue Exception => e
            return nil
          end
      else
          start_time = Time.now
          #logger.debug "Getting feed without cache" if $DEBUG == true
          f = Feedzirra::Feed.fetch_and_parse(feed.url)
          #logger.debug "debug Feedzirra::Feed.parse(content) #{f.url}" if $DEBUG == true
      end
      
      
      end_time = Time.now
      transaction_time = (end_time - start_time)
      logger.debug "Transaction Time (Feedzirra::Feed.parse) #{transaction_time} - #{feed.name}" if $DEBUG == true
      
      return f
  end
  
  def get_url(feed)
    if defined? feed.url
      url = feed.url
    elsif defined? feed.link
      url = feed.link
    else 
      url = ''
    end
    return url
  end
  
  def get_date(feed)
    if feed.dc_date
      published = feed.dc_date.to_s
    elsif  feed.pubDate
      published = feed.pubDate.to_s
    elsif feed.published
      published = feed.published.to_s
    else 
      published = ''
    end
    return published
  end
end
