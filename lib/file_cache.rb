#
# Caches API calls to a local file which is updated on a given time interval.
#
require 'open-uri'

class FileCache
  
    def initialize(file_path, cache_file, update_interval)
        @@file_path       = file_path
        @@update_interval = update_interval * 60 # minutes to seconds
        @@cache_file      = cache_file
    end
  
   
    # Updates cache if last modified is greater than
    # update interval and returns cache contents  
    
    def get_api_cache
        Rails.logger.debug "get api file cache - #{@@cache_file}"
        
        a=Time.new.to_i
        b=File.ctime(@@cache_file).to_i
        c=a-b
        Rails.logger.debug "File.ctime(@@cache_file): #{b}"
        Rails.logger.debug "if #{a} - #{b} > #{@@update_interval}"
        Rails.logger.debug "if #{c} > #{@@update_interval}"
       
        #unless  File.exist?(@@cache_file) ||
        if !File.exist?(@@cache_file) or c > @@update_interval
            Rails.logger.debug "file cache does not exist or not up to date for #{@@cache_file}"
            self.update_cache()
        end
        return self.cache_get_contents
    end
  
   
    # Makes the api call and updates the cache
    #
    def update_cache
      Rails.logger.debug "Updating cache for #{@@cache_file}"
        fp = File.new(@@cache_file, 'w')
        if fp
            # acquire an exclusive lock (writer)
            if fp.flock(File::LOCK_EX)
                content = open(@@file_path).read
  
                if content
                    #logger.debug "Generate cache file:  #{@@cache_file}"
                    fp.write(content)  # writes to the file
                end
                
                fp.flock(File::LOCK_UN) # release a lock
            end
            fp.close
        end
    end

   def cache_get_contents
       
       content = open(@@cache_file).read
       if content
           return content
       end
       
   end
end