require 'simpleassert'
require 'semantic_naming'
require 'active_support'
require 'active_record'
require 'active_rdf'
require 'source'

module TaliaCore
  
  # The TaliaCore initializer is responsible for setting up the Talia core
  # system, e.g. making the neccessary connections, setting up the
  # basic namespaces, etc.
  #
  # The basic mechanism works like the Rails initializer: Options can be
  # added to the Hash in a block that is passed to the run method of the
  # intializers.
  #
  # There are two settings that can be made before the configuration is started:
  # 
  # <tt>environmemnt</tt> is used to define the environment. This is used to
  # select the configuration options from the files. This option will default
  # to <tt>ENV['RAILS_ENV']</tt> if Talia runs in Rails. Otherwise the default
  # will be "development".
  # 
  # <tt>talia_root</tt> is the root directory for the Talia installation. If
  # unset, the will default to <tt>RAILS_ROOT</tt> in Rails and to the current
  # directory if Talia is used as a standalone module. This will be used to find
  # the configuration and data files.
  #
  # Usually these options need only to be set if running Talia standalone. In
  # this case, assign <tt>TaliaCore::Initializer.talia_root</tt> and/or
  # <tt>TaliaCore::Initializer.environment</tt> before running the 
  # configuration.
  #
  # The options may also be stored in a configuration file; the name of
  # the file is passed to the initializer.
  #
  # = Example config
  #  
  #  # If working with Rails, this code goes to the environment.rb
  #  
  #  # Set the root directory (optional, for Rails it's automatic)
  #  TaliaCore::Initializer.talia_root = "/my_directory/my_talia_root/"
  #  # Set the environment (optional, automatic for rails)
  #  TaliaCore::Initializer.environment = "development"
  #  
  #  # Run the initializer, giving a config file
  #  # See the example config files for options
  #  TaliaCore::Initializer.run("talia_core.yml") do |config|
  #    # Give more confi options. These will overwrite the ones from the 
  #    # config file
  #    config['standalone_db'] = "true"
  #  end
  class Initializer
    
    # Is used to set the root directory manually. Must be written before
    # the configuration is run.
    cattr_writer :talia_root
    
    # Is used to manually set the environment. Must be written before
    # the configuration is run.
    cattr_writer :environment
    
    # Indicates if the system has been initialized
    cattr_reader :initialized
    @@initialized = false
    
    # Indicates if the initialization was started, 
    # but not finished
    cattr_reader :init_started
    @@init_started = false
    
    # Runs the initialization. You can pass a block to this method, which
    # is run with one parameter: A hash containing the configuration.
    # 
    # If a configuration file is given, the contents will be read before the
    # block is called, the block values will overwrite the settings from the
    # file.
    # 
    # For now, the values are documented in the code below and in the default
    # configuration file.
    def self.run(config_file = nil, &initializer)
      raise(SystemInitializationError, "System cannot be initialized twice") if(@@initialized || @@init_started)
      
      @@init_started = true
      
      # Set the talia root first
      set_talia_root
      
      # Set the environmnet
      set_environment
      
      
      # Start logging
      set_logger # Set the logger
      talia_logger.info("TaliaCore initializing with environmnet #{@environment}")
      
      # Load the config file if one is given
      if(config_file)
        config_file_path = File.join(TALIA_ROOT, 'config', "#{config_file}.yml")
        @config = YAML::load(File.open(config_file_path))
      else
        # Create the default configuration
        @config = create_default_config()
      end
      
      # Call the user code
      initializer.call(@config) if(initializer)
      
      # Initialize the database connection
      config_db
      
      # Initialize the ActiveRDF connection
      config_rdf
      
      # Configure the namespaces
      config_namespaces
      
      # Configure the data directory
      config_data_directory
      
      # set the $ASSERT flag
      if(@config["assert"])
        $ASSERT = true
      end
      
      @@initialized = true
      
      # Set the environment to the configuration
      @config["environment"] = @@environment
      
      # Configuration will be frozen and stored
      @config.freeze
      
      # Make the configuration available as a constant
      TaliaCore.const_set(:CONFIG, @config)
      
      talia_logger.info("TaliaCore initialization complete")
    end
    
    
    
  protected
  
    # Creates the default values for the config hash
    def self.create_default_config
      config = Hash.new
      
      # The name of the local node
      config["local_uri"] = "http://test.dummy/"
      
      # The "default" namespace
      config["default_namespace_uri"] = "http://default.dummy/"
      
      # Connect options for ActiveRDF
      # Defaults to in-memory RDFLite
      config["rdf_connection"] = {
        :type => :rdflite
      }
      
      # Indicates if the DB backend (ActiveRecord) is 
      # used "standalone", which means "outside" a
      # rails application. 
      # For the standalone case, the Talia
      # initializer will make the database connections.
      # Otherwise, Rails will handle that.
      config["standalone_db"] = false
      
      # Configuration for standalone database connection
      config["db_connection"] = nil
      
      # Additional namespaces that will be registered at 
      # startup. If present, this is expected to be a Hash with 
      # :shortcut => URI pairs
      config["namespaces"] = nil
      
      # Whether to set the $ASSERT flag that activates the simple assertions
      config["assert"] = true
      
      # Where to find the data directory which will be contain the data
      config["data_directory_location"] = File.join(TALIA_ROOT, 'data')
      
      return config
    end
    
    
    # Creates a logger if no logger is defined
    # At the moment, this just creates a logger to the default director
    def self.set_logger
      unless(defined?(talia_logger))
        Object.instance_eval do
          def talia_logger
            @talia_logger ||= Logger.new(File.join(TALIA_ROOT, 'log', 'talia_core.log'))
          end
        end
      end
    end
    
    # Set the Talia root directory first. Use the configured directory
    # if given, otherwise go for the RAILS_ROOT/current directory.
    def self.set_talia_root
      root = if(@@talia_root)
        @@talia_root
      elsif(defined?(RAILS_ROOT))
        RAILS_ROOT
      else
        '.'
      end
      # Use the full path for the root
      Object.const_set(:TALIA_ROOT, File.expand_path(root))
    end
    
    # Set the environmet to be used for config selection
    def self.set_environment
      if(@@environment)
        @environment = @@environment
      elsif(ENV['RAILS_ENV'])
        @environment = ENV['RAILS_ENV']
      else
        @environment = "development"
      end
      @@environment = @environment
    end
    
    # Gets connection options from a file. The default_opts are the ones
    # that will be used if no file is given. If both file and default are given,
    # the method will overwrite the defaults.
    def self.connection_opts(default_opts, config_file)
      options = default_opts
      
      # First check for the file
      if(config_file)
        if(default_opts)
          talia_logger.warn("Database options will be overwritten by config file values.")
        end
        
        config_path = File.join(TALIA_ROOT, 'config', "#{config_file}.yml")
        options = YAML::load(File.open(config_path))[@environment]
      end
      
      options
    end
    
    # The connection options for the standalone database connection
    def self.db_connection_opts
      connection_opts(@config["db_connection"], @config["db_file"])
    end
    
    # Gets the db log file
    def self.db_logfile
      if(@config["db_log"])
        @config["db_log"]
      else
        File.join(TALIA_ROOT, 'log', 'database.log')
      end
    end
    
    # Configure the database connection
    def self.config_db
      # Initialize the database connection
      if(@config["standalone_db"])
        talia_logger.info("TaliaCore using standalone database")
    
        ActiveRecord::Base.establish_connection(db_connection_opts)
        ActiveRecord::Base.logger = Logger.new(db_logfile)
      else
        talia_logger.info("TaliaCore using exisiting database connection.")
      end
    end
    
    # Get the RDF configuration options
    def self.rdf_connection_opts
      options = connection_opts(@config["rdf_connection"], @config["rdf_connection_file"])
      # Make the keys into symbols, as needed by ActiveRDF
      rdf_cfg = Hash.new
      options.each { |key, value| rdf_cfg[key.to_sym] = value }
      
      rdf_cfg
    end
    
    # Configure the RDF connection
    def self.config_rdf
      ConnectionPool.add_data_source(rdf_connection_opts)
    end
    
    # Configure the namespaces
    def self.config_namespaces
      # Register the local name
      N::Namespace.shortcut(:local, @config["local_uri"])
      talia_logger.info("Local Domain: #{N::LOCAL}")
      
      # Register the default name
      N::Namespace.shortcut(:default, @config["default_namespace_uri"])
      talia_logger.info("Default Dome: #{N::DEFAULT}")
      
      # Register namespace for database dupes
      N::Namespace.shortcut(:talia_db, "http://talia.discovery-project.eu/wiki/DatabaseDupes#")
      
      # Register the RDF namespace, since the Source class depends on it
      N::Namespace.shortcut(:rdf, "http://www.w3.org/1999/02/22-rdf-syntax-ns#")
      
      # Register additional namespaces
      if(@config["namespaces"])
        sassert_type(@config["namespaces"], Hash)
        @config["namespaces"].each_pair do |shortcut, uri|
          N::Namespace.shortcut(shortcut, uri)
        end
      end
    end
    
    # Configure the data directory
    def self.config_data_directory
      data_directory = if(@config['data_directory_location'])
        # Replace the data directory location variables
        @config["data_directory_location"].gsub!(/TALIA_ROOT/, TALIA_ROOT)
      else
        File.join(TALIA_ROOT, 'data')
      end
      
      @config['data_directory_location'] = data_directory
    end
    
  end
end