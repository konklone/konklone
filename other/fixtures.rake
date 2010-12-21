namespace :fixtures do

  desc "Load all fixtures, or one model's"
  task :load => :environment do
    fixtures = ENV['model'] ? [ENV['model']] : all_fixtures
    fixtures.each {|name| restore_fixture name}
  end
  
  desc "Dump all models into fixtures, or one model"
  task :dump => :environment do
    fixtures = ENV['model'] ? [ENV['model']] : all_fixtures
    fixtures.each {|name| dump_fixture name}
  end
  
  def all_fixtures
    Dir.glob("other/fixtures/*.yml").map {|f| File.basename(f, ".yml")}
  end

end

def restore_fixture(name)
  model = name.singularize.camelize.constantize
  model.delete_all
  
  YAML::load_file("other/fixtures/#{name}.yml").each do |row|
    record = model.new
    row.keys.each do |field|
      if row[field] != "" and !row[field].nil?
        if field =~ /_id$/
          record[field] = BSON::ObjectId(row[field])
        else
          record[field] = row[field] 
        end
      end
    end
    record.save
  end
  
  puts "Loaded #{name} collection from fixtures"
end

def dump_fixture(name)
  collection = Mongoid.database.collection name
  records = []
  
  collection.find({}).each do |record|
    records << record_to_hash(record)
  end
  
  FileUtils.mkdir_p "other/fixtures"
  File.open("other/fixtures/#{name}.yml", "w") do |file|
    YAML.dump records, file
  end
  
  puts "Dumped #{name} collection to fixtures"
end

def record_to_hash(record)
  return record unless record.class == BSON::OrderedHash
  
  new_record = {}
  
  record.each do |key, value|
  
    if value.class == Array
      new_record[key] = value.map {|object| record_to_hash object}
    elsif value.class == BSON::ObjectId
      new_record[key] = value.to_s
    else
      new_record[key] = record_to_hash value
    end
    
  end
  
  new_record
end