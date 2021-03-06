class FeedEntry < ActiveRecord::Base
  include Collectible
  picable :picurl, :picture

  attr_accessible :guid, :title, :published_at, :summary, :url, :feed, :recipe

  belongs_to :recipe
  belongs_to :feed
  delegate :site, :to => :feed

  def self.update_from_feed(feed)
    feedz = Feedjira::Feed.fetch_and_parse(feed.url)
    add_entries(feedz.entries, feed) if feedz.respond_to? :entries
  end
  
  def self.update_from_feed_continuously(feed, delay_interval = 1.day)
    feedz = Feedjira::Feed.fetch_and_parse(feed.url)
    add_entries(feedz.entries, feed)
    loop do
      sleep delay_interval
      feedz = Feedjira::Feed.update(feedz)
      add_entries(feedz.new_entries, feed) if feedz.updated?
    end
  end

  private
  
  def self.add_entries(entries, feed)
    entries.each do |entry|
      entry.published = Time.current unless entry.published
      unless exists? :guid => entry.id
        create!(
          :title        => entry.title,
          :summary      => entry.summary,
          :url          => entry.url,
          :published_at => entry.published,
          :guid         => entry.id,
          :feed         => feed
        )
      end
    end
  end
end
