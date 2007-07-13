require 'objectproperties' # Includes the class methods for the object_properties
require 'local_store/source_record'
require 'active_rdf'
require 'semantic_naming'
require 'dummy_handler'

module TaliaCore
  
  # This represents a Source in the Talia core system.
  class Source
    # The elements tagged with object_property will be properties
    # passed to the local database. These elements need to be
    # in sync with the database schema
    #
    # TODO: We will need some validation for this
    # IDEA: In future version, we could try to hook into the schema
    #       to do this automatically
    
    # The URI that idefifies the source
    object_property :uri
    
    # This a descriptive name
    object_property :name
    
    # This indicates if the source is a primary source in this library
    object_property :primary_source
    
    # The work flow state
    object_property :workflow_state
  
    
    # Creates a new Source from a uri
    # If a source with the given URI already exists, this will load the given
    # source (no types can be given in that case)
    def initialize(uri, *types)
      
      existing_record = nil
      
      if(SourceRecord.exists_uri?(uri.to_s))
        if(types && types.size > 0)
          raise(DuplicateIdentifierError, 
            "Source already exists, cannot create with new type information: " + uri)
        end
        existing_record = SourceRecord.find_by_uri(uri.to_s)
      end
      
      if(existing_record)
        load_record(existing_record)
      else
        create_record(uri, types)
      end
      
    end
    
    
    # Indicates if this source belongs to the local store
    def local
      uri.local?
    end
    
    # Check if this object is valid.
    # This checks if the constraints for the Source are met.
    # Currently this only checks the constraints on the database
    # object.
    def valid?
      @source_record.valid? 
    end
    
    # Saves the data for this resource
    def save()
      # TODO: Add permission checking
      
      # We wrap this in a transaction: If the RDF save fails,
      # the database save will be rolled back
      SourceRecord.transaction do
        @source_record.save()
        # FIXME: RDF connection isn't there yet
        @rdf_resource.save()
      end
    end
    
    # Returns a list of data objects, or nil if the Source has no data
    # TODO: Check: Note that the data will be stored in the object_store,
    #       but is not an object_property. This is because this is
    #       something that requires extra handling.
    def data
      # TODO: Implementation missing
      # TODO: Permission checks for some data types?
    end
    
    # Accessor for the error messages (after validation)
    # At the moment, these are only the object store messages
    def errors
      return @source_record.errors
    end
    
    # Find Sources in the system
    # TODO: Needs specification!
    def self.find(*params)
      find_result = nil
      
      # If we have one parameter, it will be the URL 
      # of the item to load
      if(params.size == 1)
        source_record = SourceRecord.find_by_uri(params[0].to_s)
        find_result = Source.new(source_record.uri)
      else
        # FIXME: Complex find still missing
        sassert(false, "Find not yet implemented")
      end
      
      sassert_type(find_result, Source)
      return find_result
    end
    
    # Checks if a source with the given uri exists in the system
    def self.exists?(uri)
      # A source exists if the respective record exists in the
      # database store
      return SourceRecord.exists_uri?(uri.to_s)
    end
    
    protected
    
    # Creates a brand new Source object
    def create_record(uri, *types)
      
      # Contains the interface to the part of the data that is
      # stored in the database
      @source_record = SourceRecord.new(uri.to_s)
      
      # Contains the interface to the ActiveRDF 
      @rdf_resource = RDFS::Resource.new(uri.to_s)
      
      # Contains the type objects for the source
      @source_types = Array.new
      
      
      # Insert the types
      for type in types do
        type_uri = N::SourceClass.new(type)
        @source_record.types.push(SrecordType.new(type_uri))
        @source_types.push(type_uri)
      end
    end
    
    # Loads an existing record into the system
    def load_record(existing_record)
      sassert_type(existing_record, SourceRecord)
      sassert_not_nil(existing_record.uri)
      
      # Our local store is the record given to us
      @source_record = existing_record
      
      # Create the RDF object
      @rdf_resource = RDFS::Resource.new(existing_record.uri.to_s)
      
      # Create the type hash
      @source_types = Array.new
      
      # Load the type information
      for type in existing_record.types
        @source_types.push(N::SourceClass.new(type.type_uri))
      end
      
    end
    
    # Missing methods: We assume that all calls that are not handled
    # explicitly are property requests that can be answered by
    # the RDF store.
    # 
    # There are 3 possibilities here, which are processed in that order:
    # 
    # 1. The method name is a shortcut for a PredicateType. In that
    #    case, we use that predicate for the resource. We don't expect
    #    any arguments.
    #    OR
    #    The method name is a shortcut for a generic URI, in which case we
    #    use it like a predicate
    # 2. The method name is the shortcut for a Namespace. In that case,
    #    we expect an argument which can be appended to the Namespace
    #    as a string
    # 3. The method name is unknown, in which case we use it in the
    #    default namespace.
    def method_missing(method_name, *args)
      # TODO: Add permission checking for all updates to the model
      # TODO: Add permission checking for read access?
      
      update = method_name.to_s[-1..-1] == '='
      shortcut = if update 
                     method_name.to_s[0..-2]
                   else
                     method_name.to_s
                   end
      
      arg_count = update ? (args.size - 1) : args.size
      
      registered = N::URI[shortcut.to_s]
      predicate = nil
      
      if(!registered)
        # Possibility 4.
        predicate = N::DEFAULT + shortcut.to_s
      elsif(registered.kind_of?(N::Namespace))
        # Possibility 2.
        raise(SemanticNamingError, "Namespace invoked incorrectly") if(arg_count != 0)
        # Return "dummy handler" that will catch the namespace::name invocation
        return DummyHandler.new(registered, @rdf_resource)
      elsif(registered.kind_of?(N::SourceClass))
        raise(SemanticNamingError, "Can't use source class as a predicate.")
      elsif(registered.kind_of?(N::URI))
        # Possibility 1.: Predicate or generic URI
        raise(SemanticNamingError, "No additional parameters can be given with predicate") if(arg_count != 0)
        predicate = registered
      else
        # Error: Wrong type
        raise(SemanticNamingError, "Unexpected type in semantic naming")
      end
      
      if update
        @rdf_resource[predicate.to_s] = args[-1]
      else
        @rdf_resource[predicate.to_s]
      end
    end
    
    
    # Create find parameters for SourceRecord.find() from
    # the parameters that were passed to the find method of
    # this class
    
  end
end