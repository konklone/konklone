#!/usr/bin/env ruby

require 'articling'

def clean(text)
  text = text.strip
  text.gsub! /<br><br>[\n\r]+<a href="(?:\.\.\/)?comments\/[\w\d]+\.htm">[\w\d\(\)\s\/]+<\/a>$/i, ''
  text.gsub! "&nbsp;&nbsp;", ' '
  text.gsub! "&nbsp;", ' '
  text.gsub! /[\n\r]/, ''
  text.gsub! /\s*<br>\s*/i, "\n"
  lowercase_tags(text).strip
end

def lowercase_tags(text)
  text.gsub! "<U>", "<u>"
  text.gsub! "</U>", "</u>"
  text.gsub! "<I>", "<i>"
  text.gsub! "</I>", "</i>"
  text.gsub! "<B>", "<b>"
  text.gsub! "</B>", "</b>"
  text.gsub! "</A>", "</a>"
  text.gsub! "<A HREF", "<a href"
  text.gsub! "IMG>", "img>"
  text
end

def urlify(url)
  url and url !~ /^http:\/\// ? "http://#{url}" : url
end

def get_articles
  article_count = 1
  # get the oldest, just in archive files, without any comments
  filenames = Dir.glob 'archives/*.htm'
  filenames.each do |filename|
    file = File.read filename
    entries = file.scan /<div class="comment">.+?<\/div>/im 
    
    # reverse them to go from oldest to newest (not important, but whatever)
    entries.reverse.each do |entry|  
      if title = entry.match(/<span class="heading">(.+?)<\/span>/i)
        title = lowercase_tags title[1]
      else
        puts "MISSING title from #{entry}"
      end
      
      if time = entry.match(/<span class="date">--\s?(.+?)<\/span>/i)
        time = Time.parse time[1]
      else
        puts "MISSING time from #{entry}"
      end
      
      if body = entry.match(/<\/span>[\n\r\s]*<br><br>(.+?)<\/div>/mi)
        body = body[1]
      else
        puts "MISSING body from #{entry}"
      end
      
      body = clean body
      
      if body =~ /Comments/ and body =~ /\/comments\//
        puts "#{filename}: #{title}"
      end
      
      Article.create!(
        :slug => Article.slug_for(title),
        :tags => [],
        :type => "blog",
        :private => true,
        
        :imported_at => Time.now,
        :source => "blog1", 
        
        :title => title, 
        :created_at => time,  
        :body => body,
        
        :source_filename => filename
      )
      article_count += 1
    end
  end

  puts "Articles loaded: #{article_count-1}"
end


def get_comments
  comment_count = 1
  filenames = Dir.glob "comments/main/*.htm"
  filenames.each do |filename|
    file = File.read filename
    n = filename.match(/main(\d+).htm/)[1].to_i
    
    entries = file.scan /<div class="comment"(?:[^>]+)?>.+?<\/div>/im 
    title_div = entries.shift
    comment_form = entries.pop
    
    if title = title_div.match(/<span class="heading">(.+?)<\/span>/i)
      title = lowercase_tags title[1]
    end

    unless article = Article.first(:conditions => {:title => title})
      puts "COULDN'T LOCATE ARTICLE BY TITLE: #{title} from #{filename}"
      exit
    end
    
    # from main1 through main77, comments are in reverse chronological order
    entries = entries.reverse if n < 78
    
    entries.each_with_index do |comment, i|
      if name = comment.match(/<b>Comment!<\/b><br>Name: (.*?)<br>/im)
        author_name = name[1]
        author_url = nil
      elsif name = comment.match(/<a class="commentname"(?:\s+href="(.*?)")?>(.*?)<\/a>/im)
        author_url = urlify name[1]
        author_name = name[2]
      else
        puts "COULDN'T FIND NAME OF COMMENTER ON COMMENT #{i} IN #{filename}"
        exit
      end
      
      if time = comment.match(/<span class="date">--\s?(.+?)<\/span>/i)
        time = Time.parse time[1]
      else
        # we'll absorb the parent article's time, then
        time = article.created_at
      end
      
      if body = comment.match(/<br><br>Comment:<br>(.*?)<br><br><\/div>/im)
        body = clean body[1]
      elsif body = comment.match(/<span class="date">--.+?<\/span><br>[\n\r]+<br>(.+?)[\n\r]*<br><br>[\n\r]*<\/div>/im)
        body = clean body[1]
      else
        puts "COULDN'T FIND BODY OF COMMENT #{i} BY #{author_name} on #{filename}"
        exit
      end
      
      begin
        attributes = {
          :article_slug => article.slug,
          :author_name => author_name,
          :author_url => author_url,
          :created_at => time,
          :body => body,
          
          :imported_at => Time.now,
          :source => "blog1",
          :hidden => false,
          
          :source_filename => filename
        }
        Comment.create! attributes
      rescue
        puts "ERROR SAVING COMMENT #{i} BY #{author_name} on #{filename}, attributes:\n#{attributes.inspect}"
        exit
      end
    end
    
    comment_count += entries.size
  end

  puts "Comments loaded: #{comment_count-1}"
end


Article.delete_all :conditions => {:source => "blog1"}
Comment.delete_all :conditions => {:source => "blog1"}

Dir.chdir "importers/blog1"

get_articles
get_comments