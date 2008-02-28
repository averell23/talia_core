# require 'objectproperties' # Includes the class methods for the object_properties
require 'local_store/source_record'
require 'local_store/data_record'
require 'pagination/source_pagination'
require 'query/source_query'
require 'active_rdf'
require 'semantic_naming'
require 'dummy_handler'
require 'rdf_resource'
require 'rdf_helper'
require 'type_list'

module TaliaCore
  
  # This represents a Source in the Talia core system.
  #
  # Since data for the Source exists both in the database and in the RDF store, the 
  # handling/saving of data is a bit peculiar at the moment (subject to change in the future):
  #
  # * When a new Source is created, no data is saved
  # * RDF properties *cannot* be written until the Source has been saved for the first time
  # * Database properties are *only* written when the save method is called
  # * RDF properties are written immediately when they are assigned
  # * To ensure that the data is written, the save method should be called as 
  #   necessary.
  class Source
    
    # Creates a new Source from a uri
    # If a source with the given URI already exists, this will load the given
    # source (no types can be given in that case)
    #
    # If a new record is created, the empty record will be *immediately* saved to the database.
    # This is to avoid "orpahn" RDF records.
    def initialize(uri, *types)
      return load_record(uri) if(uri.is_a?(SourceRecord)) # Shortcut if a record is given directly
      
      existing_record = nil
      
      uri = Source.build_query_uri(uri)
      
      if(SourceRecord.exists_uri?(uri))
        if(types && types.size > 0)
          raise(DuplicateIdentifierError, 
            "Source already exists, cannot create with new type information: " + uri)
        end
        existing_record = SourceRecord.find_by_uri(uri)
      end
      
      if(existing_record)
        load_record(existing_record)
      else
        create_record(uri, types)
      end
    end
    
    # Get the id for this record (equals to it's local name)
    def id
      uri.local_name
    end
    
    # Alias for id, used by Rails magic
    alias_method :to_param, :id
    
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
    
    # Saves the data for this resource. On success, it will return the
    # record itself, upon failure it will return nil.
    def save()
      retval = self
      begin
        save!
      rescue
        retval = nil
      end
      
      retval
    end
    
    # Saves the data for this resource and raises error on Failure.
    # This will perform three actions:
    # 
    # * Remove the duplicated db entries from the RDF store
    # * Write the database record
    # * Write th duplicated db entries to the RDF store.
    #
    # If one of the operations fails, the database transaction will be rolled 
    # back. The RDF transaction cannot be rolled back, but this guarantees that
    # upon a successful save the "duplicate" values are written.
    def save!()
      # TODO: Add permission checking
      
      # We wrap this in a transaction: If the RDF save fails,
      # the database save will be rolled back
      SourceRecord.transaction do
        remove_db_dupes!
        @source_record.save!()
        write_db_dupes!
      end
      
      @exists = true
    end

    
    # Accessor for the error messages (after validation)
    # At the moment, these are only the object store messages
    def errors
      return @source_record.errors
    end
    
    # Wrapping for <tt>ActiveRecord</tt> <tt>update_attributes</tt>.
    def update_attributes(attributes)
      @source_record.update_attributes(attributes)
    end
    
    # Find Sources in the system
    # If just a single parameter (or a list of N::URI or String) is given, 
    # then we assume that these are the URIs of the Source(s) to load.
    # If one of those does not have the format of an URI, we assume that
    # it's the name of a local Source and prepend the local namespace.
    #
    # If multiple conditions are given, they will be joined by a boolean AND.
    # This uses the SourceQuery and related classes, which can also be used
    # independetly to create more complex queries.
    # 
    # The method can be used in a way similiar to the <tt>ActiveRecord::find</tt> method:
    #
    # * Find by url: You can give one or moren urls, and the method will either return a
    #   Source object (for a single url) or an Array of Source objects (for multiple urls)
    #   If not all of the given urls exist, an error will be raised.
    # * Find first: This will return the first record that is matched by the options given.
    #   remember that this may <b>not</b> be the same as the first record returned by SQL for that
    #   parameters. This is equivalent to :limit => 1 and :offset => 0
    # * Find all: This will return all records matched by the given options.
    #
    # Currently, the following options are supported:
    #
    # * <tt>:type</tt>: Give one or more Source types, the results will only contain the given types
    # * <tt>:limit</tt>: Limits the size of the result set to the given number of elements.
    # * <tt>:offset</tt>: The number of the first element that will be returned
    # * <tt>predicate</tt>: Returns only records where the "predicate" has the given value. The predicate
    #   (hash key) may be either a string or an N::URI object.
    # * <tt>:force_rdf</tt>: If set to true, the query will be executed within the
    #   RDF store completely.
    #
    # Examples for find by uri:
    #   Source.find("http://www.domain.org/thesource") # Finds one uri
    #   Source.find("http://www.domain.org/somesource", "http://www.domain.org/othersource") # Finds multiple uris
    #   Source.find("document") # Finds a resource in the local namespace
    #   Source.find(N::FOOBAR + "id") # Uses the dynamic naming to construct the uri
    #
    # Expamples for find first:
    #   Source.find(:first) # Just selects the "first" source
    #   Source.find(:first, :type => N::DEFAULT + "book") # Select by type
    #
    # Examples for find all:
    #   Source.find(:all) # Finds all Sources
    #   Source.find(:all, :type => N::DEFAULT::book) # Find all Sources of the given type
    def self.find(*params)
      raise(QueryError, "No query string given") unless(params.size > 0)

      first_param = params.first
      find_result = nil

      # If the first param is a String or URI, we query for the given URIs
      if(first_param.is_a?(String) || first_param.kind_of?(N::URI))
        uris = params.collect { |param| build_query_uri(param) }
        find_result = load_from_records(SourceRecord.find_by_uri(uris))
      else
        if(params.size == 1) # Check if it's just find :all or :first
          # Just go to the database
          if(first_param != :first && first_param != :all)
            raise(QueryError, "Illegal find scope: #{params[0]}")
          end
          find_result = load_from_records(SourceRecord.find(params[0]))
        else
          # Builds a query for the given options
          raise(QueryError, "Illegal parameters") unless(params.size == 2)
          qry_opts = params[1]

          if(first_param == :first)
            qry_opts[:limit] = 1
            qry_opts[:offset] = 0
          elsif(first_param != :all)
            raise(QueryError, "Illegal query scope #{first_param}")
          end

          options = find_query_opts(qry_opts)

          if(qry_opts.size == 0)
            # Special case: Just all/first with offset and/or limit
            find_result = load_from_records(SourceRecord.find(first_param, :limit => options[:limit], :offset => options[:offset]))
          else
            find_result = SourceQuery.new(options).execute
          end
          
          if(first_param == :first)
            assit(find_result.size == 0 || find_result.size == 1, "Illegal result size for :first: #{find_result.size}")
            find_result = find_result[0]
          elsif(first_param != :all)
            raise(QueryError, "Illegal find scope #{first_param}")
          end
        end
      end
             
      assit(find_result.is_a?(Source) || find_result.is_a?(Array) || find_result == nil)
      find_result
    end
    
    # Counts the number of Sources with the given options (see #find for how 
    # the options work. This will currently raise an exception in case 
    # the options cannot be translated to a database-only query.
    # 
    # If no options are passed, this returns the number of Sources in the 
    # system. Offset and/or limit options are silently *ignored*.
    def self.count(options = nil)
      if(options)
        options = find_query_opts(options)
      end
      if(options && options[:conditions].size > 0)
        qry = SourceQuery.new(options)
        raise(ArgumentError, "Can only work with database queries") unless(qry.is_a?(DbQuery))
        qry.result_count_all
      else
        SourceRecord.count_by_sql("SELECT COUNT(*) FROM source_records")
      end
    end
    
    # Checks if the current record already exists in the database
    def exists?
      @exists = Source.exists?(uri)
    end
    
    # Checks if a source with the given uri exists in the system
    def self.exists?(uri)
      # A source exists if the respective record exists in the
      # database store
      uri = build_query_uri(uri)
      return SourceRecord.exists_uri?(uri)
    end
    
    # Returns an array of the predicates that are directly defined for this
    # Source. This will return a list of URIs that will access valid 
    # attributes on this Source.
    def direct_predicates
      @rdf_resource.direct_predicates
    end
    
    # Returns an array of the "inverse" predicates of this source. These are
    # the predicates for which this source exists as an object
    def inverse_predicates
      qry = Query.new.distinct.select(:p)
      qry.where(:s, :p, RDFS::Resource.new(uri.to_s))
      qry.execute.collect{ |res| N::Predicate.new(res.uri) }
    end
    
    # Returns a TypeList with the types of this Source
    def types
      TypeList.new(@source_record.type_records)
    end
    
    # Redirect the call to the :type_records
    alias :type_records :types
    
    # Attribute reader, for compatibility with the ActiveRecord API
    # If the given name is a database field, the called will be
    # passed to the database. Otherwise, this will assume that 
    # the parameter is the URI of a RDF property.
    def [](attribute)
      attr = nil
      
      if(@source_record.attribute_names.include?(attribute.to_s))
        attr = @source_record[attribute.to_s]
      else
        attr = @rdf_resource[attribute.to_s]
      end
      
      attr
    end
    alias :get_attribute :[]
    
    # Assignment to the the array-type accessor
    def []=(attribute, value)
      if(@source_record.attribute_names.include?(attribute.to_s))
        @source_record[attribute.to_s] = value
      else
        raise(ArgumentError, "Set not available on RDF properties, use << instead.")
      end
    end
    alias :set_attribute :[]=
    
    # This returns a special object which collects the "inverse" properties 
    # of the Source - these are all RDF properties which have the current
    # Source as the object.
    #
    # The returned object supports the [] operator, which allows to fetch the
    # "inverse" (the RDF subjects) for the given predicate.
    #
    # Example: <tt>person.inverse[N::FOO::creator]</tt> would return a list of
    # all the elements of which the current person is the creator.
    def inverse
      @rdf_resource.inverse
    end
    
    # Accessor that allows to lookup a namespace/name combination. This works like
    # the [] method: It will return a SourcePropertyList
    def predicate(namespace, name)
      namesp_uri = N::Namespace[namespace]
      
      # Only return something if the namespace exits.
      namesp_uri ? self[namesp_uri + name.to_s] : nil
    end
    
    # Setter method for predicates by namespace/name combination. This works like
    # the = operator for a property: *It will add a precdicate triple, not replace one!*
    def predicate_set(namespace, name, value)
      raise_if_unsaved
      
      namesp_uri = N::Namespace[namespace]
      
      # Check if namespace exists
      namesp_uri ? self[namesp_uri + name.to_s] << value : false
    end
    
    # This will return a list of DataRecord objects. Without parameters, this
    # returns all data elements on the source. If a type is given, it will
    # return only the elements of the given type. If both type and location are
    # given, it will retrieve only the specified data element
    def data(type = nil, location= nil)
      find_type = location ? :first : :all # Find just one element if a location is given
      options = {}
      options[:conditions] = [ "type = ?", type ] if(type && !location)
      options[:conditions] = [ "type = ? AND location = ?", type, location ] if(type && location)
      @source_record.data_records.find(find_type, options)
    end
    
    # Returns an array of labels for this source. You may give the name of the
    # property that is used as a label, by default it uses rdf:label(s). If
    # the given property is not set, it will return the local part of this
    # Source's URI.
    #
    # In any case, the result will always be an Array with at least one elment.
    def labels(type = N::RDFS::label)
      labels = get_attribute(type)
      unless(labels && labels.size > 0)
        labels = [uri.local_name]
      end

      labels
    end
    
    # This returns a single label of the given type. (If multiple labels
    # exist in the RDF, just the first is returned.)
    def label(type = N::RDFS::label)
      labels(type)[0]
    end
    
    # Creates a simple XML representation of the Source
    def to_xml
      xml = String.new
      builder = Builder::XmlMarkup.new(:target => xml, :indent => 2)
      
      # Xml instructions (version and charset)
      builder.instruct!
      
      builder.source(:primary => primary_source) do
        builder.id(@source_record.id, :type => "integer")
        builder.uri(uri.to_s)
        builder.name(@source_record.name)
        builder.workflow_state(@source_record.workflow_state, :type => "integer")
        builder.primary_source(@source_record.primary_source, :type => "boolean")
      end
      
      xml
    end
    
    # Creates an RDF/XML resprentation of the source
    def to_rdf
      xml = String.new
      
      builder = Builder::XmlMarkup.new(:target => xml, :indent => 2)
      
      # Xml instructions (version and charset)
      builder.instruct!
      
      # Build the namespaces
      namespaces = {}
      N::Namespace.shortcuts.each { |key, value| namespaces["xmlns:#{key.to_s}"] = value.to_s }
      
      builder.rdf :RDF, namespaces do # The main RDF/XML element
        builder.rdf :Description, :about => uri do # Element describing this resource
          # loop through the predicates
          direct_predicates.each do |predicate|
            predicate_rdf(predicate, builder)
          end
        end
      end
      
    end
    
    # To string: Just return the URI. Use to_xml if you need something more
    # involved.
    def to_s
      uri.to_s
    end
    
    # Equality test. Two sources are equal if they have the same URI
    def ==(value)
      value.is_a?(Source) && (value.uri == uri)
    end
    
    # Add the uri call to the respond_to?
    def respond_to?(symbol, include_private=true)
      if(symbol == :uri)
        true
      else
        super(symbol, include_private)
      end
    end
    
    protected
    
    
    # Class methods
    class << self
      
      # Build an uri from a string that was given from a query.
      # If this already is a uri, it will just be returned. 
      # If this is not an URI, it will return a URI with the given name in the 
      # local namespace
      def build_query_uri(orig_string)
        uri = orig_string.to_s
        
        if(!N::URI.is_uri?(uri))
          uri = (N::LOCAL + uri).to_s
        end
        
        return  uri
      end
      
      # Get the "RDF name" of a DB item
      def db_item_to_rdf(item)
        if(item == :type)
          N::RDF::type
        else
          (N::TALIA_DB + item.to_s)
        end
      end
      
      # Loads a list of existing records into the system. This will
      # return an Array of Source objects, the records can be given
      # as a list of SourceRecord objects, or as a single Array.
      def load_from_records(*existing_records)
        existing_records = existing_records[0] if(existing_records[0].kind_of?(Array))
        
        existing_records = existing_records.collect { |record| Source.new(record) }
        # flatten the array if neccessary
        existing_records.size == 1 ? existing_records[0] : existing_records
      end
      
      # Transforms the options given to #find to options that can be given
      # to the SourceQuery class.
      def find_query_opts(options)
        qry_opts = {}
        qry_opts[:limit] = options.delete(:limit) if(options[:limit])
        qry_opts[:offset] = options.delete(:offset) if(options[:offset])
        qry_opts[:force_rdf] = options.delete(:force_rdf) if(options[:force_rdf])
        qry_opts[:conditions] = options
        qry_opts
      end
      
    end
    
    # End of class methods
    
    # Loads an existing record into the system
    def load_record(existing_record)
      assit_kind_of(SourceRecord, existing_record)
      assit_not_nil(existing_record.uri)
      
      # Our local store is the record given to us
      @source_record = existing_record
      
      # Create the RDF object
      @rdf_resource = RdfResource.new(existing_record.uri.to_s)  
    end
  
    # Creates a brand new Source object
    def create_record(uri, new_types)
      
      # Contains the interface to the part of the data that is
      # stored in the database
      @source_record = SourceRecord.new(uri.to_s)
      
      # Contains the interface to the ActiveRDF 
      @rdf_resource = RdfResource.new(uri.to_s)
      
      # Insert the types
      for type in new_types do
        types << N::SourceClass.new(type.to_s)
      end
      
    end
    
    # Writes the duplicates for the database properties to the
    # RDF store. Saves the rdf resource.
    def write_db_dupes!
      db_columns_each do |col|
        @rdf_resource[Source::db_item_to_rdf(col)] << @source_record[col]
      end
      # Write the types
      types.each { |type| @rdf_resource.types << N::SourceClass.new(type) }
   
      @rdf_resource.save
    end
    
    # Removes the duplicates for the database properties from the
    # RDF store. Saves the rdf resource.
    def remove_db_dupes!
      db_columns_each do |col|
        db_dupe = @rdf_resource[Source::db_item_to_rdf(col)]
        db_dupe.writeable = true # make the list writeable, even if the Source doesn't exist
        db_dupe.remove
      end
      
      # Remove the types
      types = @rdf_resource.types
      types.writeable = true # see above
      types.remove
      
      @rdf_resource.save
    end
    
    # Executes the given block for each database column, passing
    # the name of the column as a parameter. 
    #
    # This gets the columns from ActiveRecord::Base#content_columns
    def db_columns_each(&block)
      SourceRecord.content_columns.each do |col|
        block.call(col.name)
      end
    end
    
    # Raises an error if the underlying record is not saved yet
    def raise_if_unsaved
      if(!exists?)
        raise(UnsavedSourceError, "Cannot set elements on unsaved Source #{uri.to_s}.")
      end
    end
    
    # Missing methods: This first checks if the method called 
    # corresponds to a valid database attribute. In this case,
    # the call will be passed to the database.
    #
    # Otherwise, the call goes to the RDF store, as explained below.
    # 
    # There are 3 possibilities for RDF, which are processed in that order:
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
      
      # Check if this call should go to the db
      if(@source_record.attribute_names.include?(shortcut.to_s))
        if(update)
          return @source_record[shortcut.to_s] = args[-1]
        else
          return @source_record[shortcut.to_s]
        end
      end
      
      # Check for associated database records
      # This has to be checked/called "manually" because the
      # associated types are not properties of the ActiveRecord
      if(assoc = SourceRecord.reflect_on_association(shortcut.to_sym))
        case assoc.macro
        when :has_many
          return @source_record.send(shortcut.to_s)
        when :has_one
          if(update)
            return @source_record.send(method_name.to_s, args[0])
          else
            return @source_record.send(shortcut.to_s)
          end
        else
          assit(false, "Invalid association type")
          return false
        end
      end
      
      # Otherwise, check for the RDF predicate
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
        raise_if_unsaved
        @rdf_resource[predicate.to_s] << args[-1]
      else
        @rdf_resource[predicate.to_s]
      end
    end
    
    
    # Build an rdf/xml string for one predicate
    def predicate_rdf(predicate, builder)
      builder.tag!(predicate.to_name_s) do
        # Get the predicate values
        self[predicate.to_s].each do |value|
          # If we have a (re)Source, we have to put in another description tag.
          # Otherwise, we will take just the string
          if(value.kind_of?(Source))
            builder.rdf :Description, "rdf:about" => value.uri.to_s
          else
            builder.text!(value.to_s)
          end
        end # end predicate loop
      end # end tag!
    end # end method
    
    
  end
end
