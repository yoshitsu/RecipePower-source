class FeedServices
  
  # Examine a page from a site (or a given other page) for RSS feeds and return a set of possible feeds
  def self.scrape_page(site, page_url=nil)
    keepers = []
    queue = page_url ? [page_url] : [site.sample]
    visited = {}
    while (page_url = queue.shift) && (visited.length < 10)
      doc = nil
      begin 
        if(ou = open page_url)
          doc = Nokogiri::HTML(ou)
        end
      rescue Exception => e
        next
      end
      puts "SCRAPING #{page_url}..."
      candidates = {}
      # We find the following elements:
      # <a> elements where the link text OR the title attribute OR the href attribute includes 'RSS', 'rss', 'feedburner' or 'feedblitz'
      # <link> tags with type="application/rss+xml": title and href attributes
      doc.css("a").each { |link| 
        content = link.inner_html.encode("UTF-8")
        href = link.attributes["href"].to_s
        next if href == "#"
        if content.include?("RSS") || content.include?("rss") || href.match(/rss|feedburner|feedblitz|atom/i)           
          candidates[href] = content
        end
      }
      doc.css("link").each { |link|
        href = link.attributes["href"].to_s
        next if href == "#"
        if link.attributes["type"].to_s =~ /^application\/rss/i
          candidates[href] = link.attributes["title"].to_s
        end
      }
      candidates.keys.each do |href| 
        content = candidates[href].truncate(250)
        begin
          # For some strange reason we've seen feed URLs starting with 'feed:http:'
          url = URI.join( site.home, href).to_s.sub(/feed:http:/, "http:")
        rescue Exception => e
          url = nil
        end 
        next if url.blank? || visited[url]
        visited[url] = true
        unless url.blank? ||
            Feed.exists?(url: url) ||
            keepers.find { |f| f.url == url } ||
            !(feed = Feed.new( url: url, description: content))
          if feed.follow_url # save
            puts "\tCAPTURED feed #{url}"
            keepers << feed # site.feeds << feed
          else
            # puts "\tREJECTED #{url}...because\n\t"+feed.errors.collect { |k, v| k.to_s+" "+v }.join('\n\t...')
            if (url =~ /rss|xml/) && (Site.find_or_create(url) == site) # Another page on the same site with rss in the url; maybe a page of links?
              unless queue.include?(url)
                if queue.length < 10
                  puts "\tPUSHING #{url}"
                  queue.push url
                else
                  puts "\AVOIDING #{url} (too many bloody pages)"
                end
              end
            end
          end
        end
      end
      visited[page_url] = true
    end
    keepers
  end

  # Move all feeds from users' feeds list to their collection
  # TODO delete
  def self.collectify
    User.all.each { |user|
      user.feed_collections.each { |feed|
        user.collect feed
      }
      user.feed_collection_ids = []
      user.save
    }
  end
  
end
