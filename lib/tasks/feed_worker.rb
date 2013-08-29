require 'feedzirra'
require 'mysql'
require 'json'


# Sample JSON
=begin
{"feeds":[{
            "feed_title": "Birkoff.net",
            "feed_url": "",
            "entries": [{
                    "title": "",
                    "url": "",
                    "published": "",
                    "content": ""
                },
                {
                    "title": "",
                    "url": "",
                    "published": "",
                    "content": ""
                }]
        },
        {
            "feed_title": "Birkoff.net",
            "feed_url": "",
            "entries": [{
                    "title": "",
                    "url": "",
                    "published": "",
                    "content": ""
                },
                {
                    "title": "",
                    "url": "",
                    "published": "",
                    "content": ""
                }]
        }]
 }
 =end
 
 
 db_host     = $db_host
 db_port     = $db_port
 db_username = ''
 db_password = ''
 db_name     = ''
 
 @conn = Mysql.new(db_host, db_username, db_password, db_name)
 
 result = @conn.exec("select id_artist from tblartist where id_reccomp = #{account_id}")
 
 result.each do |row|
      f = Feedzirra::Feed.fetch_and_parse(feed.url)
      feed_url = f.url
        feed_title = f.title
        f.entries.each do |item|
            title     = item.title
            url       = item.url
            published = item.published.to_s
            summary   = item.summary
            p = published.split(" ")
            published = "#{p[-1]}-#{p[1]}-#{p[2]}"
            break if Date.parse(published) < Date.today # Tue Jun 04 15:16:00 UTC 2013
            @mem_feeds[i] = Currentfeed.new(feed_url, feed_title, title, url, published, summary)
            break
        end
        i+=1 unless @mem_feeds[i].nil?
        break if i>=MAX_FEED_ITEMS
 end 
