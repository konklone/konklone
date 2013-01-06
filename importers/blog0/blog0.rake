# Imports all blog posts and comments from my LiveJournal
namespace :import do
  desc "Import posts and comments from blog0"
  task blog0: :environment do
    current_dir = Dir.pwd
    Dir.chdir "importers/blog0"
    
    # Post.where(import_source: "blog0").delete_all
    Comment.where(import_source: "blog0").delete_all

    # Blog0.get_posts
    Blog0.get_comments
    
    Dir.chdir current_dir
  end
end


require 'csv'
require 'nokogiri'

module Blog0

  def self.get_posts
    post_count = 0


    months = Dir.glob("entries/*.csv").map {|path| File.basename(path, ".csv")}

    months.sort do |f1, f2|
      # sort by year and month, properly (sorting by filename does not work)
      eric, year1, month1 = f1.split "-"
      eric, year2, month2 = f2.split "-"
      if year1.to_i == year2.to_i
        month1.to_i <=> month2.to_i
      else
        year1.to_i <=> year2.to_i
      end
    end.each do |filename|
      puts "[#{filename}]"

      CSV.foreach("entries/#{filename}.csv") do |row|
        next if row[0].strip == "itemid"

        old_id = row[0].strip
        time = Time.zone.parse row[1].strip
        title = (row[3] || "untitled").strip
        body = (row[4] || "<no body>").strip
        current_music = row[7].present? ? row[7].strip : nil
        current_mood = row[8].present? ? row[8].strip : nil

        sequence = post_count + 1 # sequential

        puts "\t[#{sequence}] #{time.strftime "%Y-%m-%d"} #{title == "untitled" ? body[0..40] + "..." : title}"

        Post.create!(
          title: title,
          body: body,
          created_at: time,
          updated_at: time,
          published_at: time,
          
          tags: [],
          post_type: ["blog"],
          :private => true,
          
          imported_at: Time.now,
          import_source: "blog0", 
          import_source_filename: filename,
          import_id: old_id,
          import_sequence: sequence,
          import_current_music: current_music,
          import_current_mood: current_mood
        )
        post_count += 1
      end
    end

    puts "Posts loaded: #{post_count}\n\n"
  end


  def self.get_comments
    comment_count = 0
    
    puts "Loading map of usernames..."
    usermap = {}
    (Nokogiri::XML(open("comments/metadata.xml")) / :usermap).each do |user|
      usermap[user['id']] = user['user']
    end

    puts "Loading manual jitemid to sequence override..."
    sequences = {}
    CSV.foreach("jitemid_to_sequence.csv") do |row|
      next if row[0] == "jitemid"

      # jitemid -> sequence
      sequences[row[0]] = row[1] 
    end

    puts "Loading comments..."
    (Nokogiri::XML(open("comments/bodies.xml")) / :comment).each do |comment|
      comment_id = comment['id']
      posterid = comment['posterid']
      parentid = comment['parentid']
      sequence = sequences[comment['jitemid']] || comment['jitemid']
      deleted = comment['state'] == "D"

      unless post = Post.where(import_source: "blog0", import_sequence: sequence.to_i).first
        puts "ERROR FINDING POST #{sequence} for comment #{comment_id}"
        exit # kill it
      end
      
      if deleted
        time = post.published_at # inherit post's publish date
        subject = nil
        body = "<deleted>"
      else
        time = Time.zone.parse((comment/:date).text)
        if subject = (comment/:subject)
          subject = subject.text.present? ? subject.text : nil
        end
        body = (comment/:body).text
      end

      # is present even for deleted comments
      if posterid
        author_name = usermap[posterid]
      else
        author_name = "anonymous"
      end

      puts "\t[#{sequence}][#{comment_id}] #{time.strftime "%Y-%m-%d"} #{subject ? subject : body[0..40] + "..."}"

      attributes = {
        author: author_name,
        created_at: time,
        updated_at: time,
        body: body,
        
        imported_at: Time.now,
        import_source: "blog0",
      
        import_id: comment_id,
        import_sequence: sequence,
        import_posterid: posterid,
        import_subject: subject,
        import_parentid: parentid
      }

      comment = post.comments.build attributes
        
      # attr_protected fields, can't be mass-assigned
      comment.hidden = false
      comment.flagged = false
      
      begin
        comment.save!
      rescue
        puts "\nERROR SAVING COMMENT #{i} BY #{author_name} on #{filename}, attributes:\n#{attributes.inspect}\n#{comment.errors.full_messages.inspect}"
      end

      comment_count += 1
    end
    puts "Comments loaded: #{comment_count}\n\n"
  end
  
end