require 'rubygems'
gem 'progressbar'
require 'progressbar'
require 'ftools'

module TaliaUtil
  def import_data(files, type)
    
    # First get the class for the data type and the directory
    data_klass = get_data_class(type)
    replace = ENV['replace_files'] && (ENV['replace_files'] == "yes")
    
    progress = ProgressBar.new("Importing #{data_klass}", files.size)
    not_found = []
    created = 0
    
    files.each do |file|
      name = File.basename(file)
      if(TaliaCore::Source.exists?(name))
        src = TaliaCore::Source.find(name)
        
        # Create the record if necessary
        unless(data = src.data_records.find_by_location(name))
          data = data_klass.new
          data.location = name
          src.data_records << data
          src.save!
          data.save!
          created += 1
        end
        
        # Copy the file if necessary, overwriting the existing data
        data_file = File.expand_path(data.get_file_path)
        this_file = File.expand_path(file)
        
        if(data_file != this_file)
          File.makedirs(File.dirname(data_file))
          File.copy(this_file, data_file) if(!FileTest.exists?(data_file) || replace)
        end
      else
        not_found << file
      end
      progress.inc
    end
    
    progress.finish
    puts "Done, #{not_found.size} of #{files.size} files had no record associated."
    puts "#{created} new records created."
    puts "\nNot found:" unless(not_found.size == 0)
    not_found.each { |file| puts file}
  end
  
  
  # Get the data class for the type. That does some sanity checks 
  def get_data_class(type)
    unless(type && TaliaCore.const_defined?(type))
      puts("Must give an existing data type with the data_type=<type> option.")
      print_options
      exit(1)
    end
    
    data_klass = TaliaCore.const_get(type)
    
    # Do the basic check
    unless(data_klass && data_klass.kind_of?(Class) && data_klass.method_defined?('data_directory'))
      puts("Cannot create data class from #{type}")
      exit(1)
    end
    
    # Now check if we are a subclass of the data class
    my_instance = data_klass.new
    
    unless(my_instance.kind_of?(TaliaCore::DataRecord))
      puts("The class #{data_klass} is not a DataRecord, can't create data for it.")
      exit(1)
    end
    
    data_klass
  end
end