require 'hpricot'
require 'pathname'

module TaliaCore
  module ActiveSourceParts
    module Xml

      # Superclass for importers/readers of generic xml files. This is as close as possible
      # to the SourceReader class, and will (obviously) only work if a subclass fleshes out
      # the mappings.
      #
      # See the SourceReader class for a simple example.
      #
      # When adding new sources, the reader will always check if the element is already
      # present. If attributes for one source are imported in more than one place, all
      # subsequent calls will merge the newly imported attributes with the existing ones.
      class GenericReader
        

        extend TaliaUtil::IoHelper
        include TaliaUtil::IoHelper
        include TaliaUtil::Progressable
        include TaliaUtil::UriHelper

        # Helper class for state
        class State
          attr_accessor :attributes, :element
        end

        class << self

          # See the IoHelper class for help on the options. A progressor may
          # be supplied on which the importer will report it's progress.
          def sources_from_url(url, options = nil, progressor = nil)
            open_generic(url, options) { |io| sources_from(io, progressor, url) }
          end

          # Reader the sources from the given IO stream. You may specify a base
          # url to help the reader to decide from where files should be opened.
          def sources_from(source, progressor = nil, base_url=nil)
            reader = self.new(source)
            reader.base_file_url = base_url if(base_url)
            reader.progressor = progressor
            reader.sources
          end

          # Create a handler for an element from which a source will be created
          def element(element_name, &handler_block)
            element_handler(element_name, true, &handler_block)
          end

          # Create a handler for an element which will be processed but from which
          # no source will be created
          def plain_element(element_name, &handler_block)
            element_handler(element_name, false, &handler_block)
          end

          # Set the reader to allow the use of root elements for import
          def can_use_root
            @use_root = true
          end

          # True if the reader should also check the root element, instead of
          # only checking the children
          def use_root
            @use_root || false
          end

          # Returns the registered handlers
          attr_reader :create_handlers

          private

          # Adds an handler for the the given element. The second parameter will
          # indicate if the handler will create a new source or not
          def element_handler(element_name, creating, &handler_block)
            element_name = "#{element_name}_handler".to_sym
            raise(ArgumentError, "Duplicate handler for #{element_name}") if(self.respond_to?(element_name))
            raise(ArgumentError, "Must pass block to handler for #{element_name}") unless(handler_block)
            @create_handlers ||= {}
            @create_handlers[element_name] = creating # Indicates whether a soure is created
            # Define the handler block method
            define_method(element_name, handler_block)
          end
        end # End class methods

        def initialize(source)
          @doc = Hpricot.XML(source)
        end

        def sources
          return @sources if(@sources)
          @sources = {}
          if(use_root && self.respond_to?("#{@doc.root.name}_handler".to_sym))
            run_with_progress('XmlRead', 1) { read_source(@doc.root) }
          else
            read_children_with_progress(@doc.root)
          end
          @sources.values
        end
        
        # This is the "base" for resolving file URLs. If a file URL is found
        # to be relative, it will be relative to this URL
        def base_file_url
          @base_file_url ||= TALIA_ROOT
        end
        
        # Assign a new base url
        def base_file_url=(new_base_url)
          @base_file_url = base_for(new_base_url)
        end

        def add_source_with_check(source_attribs)
          assit_kind_of(Hash, source_attribs)
          if((uri = source_attribs['uri']).blank?)
            raise(RuntimeError, "Problem reading from XML: Source without URI (#{source_attribs.inspect})")
          else
            uri = irify(uri)
            source_attribs['uri'] = uri
            @sources[uri] ||= {} 
            @sources[uri].each do |key, value|
              next unless(new_value = source_attribs.delete(key))

              assit(!((key.to_sym == :type) && (value != 'TaliaCore::SourceTypes::DummySource') && (value != new_value)), "Type should not change during import, may be a format problem. (From #{value} to #{new_value})")
              if(new_value.is_a?(Array) && value.is_a?(Array))
                # If both are Array-types, the new elements will be appended
                # and duplicates will be removed
                @sources[uri][key] = (value + new_value).uniq
              else
                # Otherwise just replace
                @sources[uri][key] = new_value
              end
            end
            # Now merge in everything else
            @sources[uri].merge!(source_attribs)
          end
        end

        def create_handlers
          @handlers ||= (self.class.create_handlers || {})
        end

        def read_source(element, &block)
          attribs = call_handler(element, &block)
          add_source_with_check(attribs) if(attribs)
        end

        def read_children_with_progress(element, &block)
          run_with_progress('Xml Read', element.children.size) do |prog|
            read_children_of(element, prog, &block)
          end
        end

        def read_children_of(element, progress = nil, &block)
          element.children.each do |element|
            progress.inc if(progress)
            next unless(element.is_a?(Hpricot::Elem))
            read_source(element, &block)
          end
        end

        def use_root
          self.class.use_root
        end

        private

        # Call the handler method for the given element. If a block is given, that
        # will be called instead
        def call_handler(element)
          handler_name = "#{element.name}_handler".to_sym
          if(self.respond_to?(handler_name) || block_given?)
            parent_state = @current # Save the state for recursive calls
            attributes = nil
            begin
              creating = (create_handlers[handler_name] || block_given?)
              @current = State.new
              @current.attributes = creating ? {} : nil
              @current.element = element
              block_given? ? yield : self.send(handler_name)
              attributes = @current.attributes
            ensure
              @current = parent_state # Reset the state to previous value
            end
            attributes
          else
            TaliaCore.logger.warn("Unknown element in import: #{element.name}")
            false
          end
        end

        def chk_create
          raise(RuntimeError, "Illegal operation when not creating a source") unless(@current.attributes)
        end

        # Adds a value for the given predicate (may also be a database field)
        def add(predicate, object, required = false)
          # We need to check if the object elements are already strings -
          # otherwise we would *.to_s the PropertyString objects, which would
          # destroy the metadata in them.
          if(object.kind_of?(Array))
            object.each { |obj| set_element(predicate, obj.is_a?(String) ? obj : obj.to_s, required) }
          else
            set_element(predicate, object.is_a?(String) ? object : object.to_s, required)
          end
        end
        
        # Adds a value with the given prediate and language/type information
        def add_i18n(predicate, object, lang, type=nil)
          object = object.blank? ? nil : TaliaCore::PropertyString.new(object, lang, type)
          add(predicate, object)
        end
        
        # Adds a date field. This will attempt to parse the original string
        # and write the result as an ISO 8061 compliant date string. Note
        # that this won't be able to parse everything you throw at it, though.
        def add_date(predicate, date, required = false, fmt = nil)
          add(predicate, to_iso8601(parse_date(date, fmt)), required)
        end
        
        # Adds a date interval as an ISO 8061 compliant date string. See
        # add_date for more info. If only one of the dates is given this
        # will add a normal date string instead of an interval.
        def add_date_interval(predicate, start_date, end_date, fmt = nil)
          return if(start_date.blank? && end_date.blank?)
          if(start_date.blank?)
            add_date(predicate, start_date, true, fmt)
          elsif(end_date.blank?)
            add_date(predicate, end_date, true, fmt)
          else
            add(predicate, "#{to_iso8601(parse_date(start_date, fmt))}/#{to_iso8601(parse_date(end_date, fmt))}", required)
          end
        end

        # Adds a relation for the given predicate
        def add_rel(predicate, object, required = false)
          object = check_objects(object)
          if(!object)
            raise(ArgumentError, "Relation with empty object on #{predicate} (#{@current.attributes['uri']}).") if(required)
            return
          end
          if(object.kind_of?(Array))
            object.each do |obj| 
              raise(ArgumentError, "Cannot add relation on database field <#{predicate}> - <#{object.inspect}>") if(ActiveSource.db_attr?(predicate))
              set_element(predicate, "<#{irify(obj)}>", required) 
            end
          else
            raise(ArgumentError, "Cannot add relation on database field") if(ActiveSource.db_attr?(predicate))
            set_element(predicate, "<#{irify(object)}>", required)
          end
        end

        # Add a file to the source being imported. See the DataLoader module for a description of
        # the possible options
        def add_file(urls, options = {})
          return if(urls.blank?)
          urls = [ urls ] unless(urls.is_a?(Array))
          files = urls.collect { |url| { :url => get_absolute_file_url(url), :options => options } }
          @current.attributes[:files] = files if(files.size > 0)
        end

        # Gets an absolute path to the given file url, using the base_file_url
        def get_absolute_file_url(url)
          orig_url = url.to_s.strip
          
          url = file_url(orig_url)
          # If a file:// was stripped from the url, this means it will always point
          # to a file
          force_file = (orig_url != url)
          # Indicates wether the base url is a network url or a file/directory
          base_is_net = !base_file_url.is_a?(String)
          # Try to find if we have a "net" URL if we aren't sure if this is a file. In
          # case the base url is a network url, we'll always assume that the
          # url is also a net thing. Otherwise we only have a net url if it contains a
          # '://' string
          is_net_url = !force_file && (base_is_net || url.include?('://'))
          # The url is absolute if there is a : character to be found
          
          
          if(is_net_url)
            base_is_net ? join_url(base_file_url, url) : url
          else
            base_is_net ? url : join_files(base_file_url, url)
          end
        end
        
        # Joins the two files. If the path is an absolute path,
        # the base_dir is ignored
        def join_files(base_dir, path)
          if(Pathname.new(path).relative?)
            File.join(base_dir, path)
          else
            path
          end
        end
        
        # Joins the two url parts. If the path is an absolute URL,
        # the base_url is ignored.
        def join_url(base_url, path)
          return path if(path.include?(':')) # Absolute URL contains ':'
          if(path[0..0] == '/')
            new_url = base_url.clone
            new_url.path = path
            new_url.to_s
          else
            (base_file_url + path).to_s
          end
        end

        # Returns true if the given source was already imported. This can return false
        # if you call this for the currently importing source. 
        def source_exists?(uri)
          !@sources[uri].blank?
        end

        # Adds a source from the given sub-element. You may either pass a block with
        # the code to import or the name of an already registered element. If the
        # special value :from_all_sources is given, it will read from all sub-elements for which
        # there are registered handlers
        def add_source(sub_element = nil, &block)
          if(sub_element)
            if(sub_element == :from_all_sources)
              read_children_of(@current.element)
            else
              @current.element.search("/#{sub_element}").each { |sub_elem| read_source(sub_elem, &block) }
            end
          else
            raise(ArgumentError, "When adding elements on the fly, you must use a block") unless(block)
            attribs = call_handler(@current.element, &block)
            add_source_with_check(attribs) if(attribs)
          end
        end

        # Returns true if the currently imported element already contains type information
        # AND is of the given type.
        def current_is_a?(type)
          assit_kind_of(Class, type)
          @current.attributes['type'] && ("TaliaCore::#{@current.attributes['type']}".constantize <= type)
        end

        # Adds a nested element. This will not change the currently importing source, but
        # it will set the currently active element to the nested element. 
        # If a block is given, it will execute for each of the nested elements that
        # are found. Otherwise, a method name must be given, and that method will
        # be executed instead of the block
        def nested(sub_element, handler_method = nil)
          original_element = @current.element
          begin
            @current.element.search("#{sub_element}").each do |sub_elem|
              @current.element = sub_elem
              assit(block_given? ^ (handler_method.is_a?(Symbol)), 'Must have either a handler (x)or a block.')
              block_given? ? yield : self.send(handler_method)
            end
          ensure
            @current.element = original_element
          end
        end

        # Imports another source like add_source and also assigns the new source as
        # a part of the current one
        def add_part(sub_element = nil, &block)
          raise(RuntimeError, "Cannot add child before having an uri to refer to.") unless(@current.attributes['uri'])
          @current.element.search("/#{sub_element}").each do |sub_elem|
            attribs = call_handler(sub_elem, &block)
            if(attribs)
              attribs[N::TALIA.part_of.to_s] ||= []
              attribs[N::TALIA.part_of.to_s] << "<#{@current.attributes['uri']}>"
              add_source_with_check(attribs)
            end
          end
        end

        # Add a property to the source currently being imported
        def set_element(predicate, object, required)
          chk_create
          object = check_objects(object)
          if(!object)
            raise(ArgumentError, "No object given, but is required for #{predicate}.") if(required)
            return
          end
          predicate = predicate.respond_to?(:uri) ? predicate.uri.to_s : predicate.to_s
          if(ActiveSource.db_attr?(predicate))
            assit(!object.is_a?(Array))
            @current.attributes[predicate] = object
          else
            @current.attributes[predicate] ||= []
            @current.attributes[predicate] << object
          end
        end

        # Check the objects and sort out the blank ones (which should not be used).
        # If no usable object 
        def check_objects(objects)
          if(objects.kind_of?(Array))
            objects.reject! { |obj| obj.blank? }
            (objects.size == 0) ? nil : objects
          else
            objects.blank? ? nil : objects
          end
        end

        # Get an attribute from the current xml element
        def from_attribute(attrib)
          @current.element[attrib]
        end

        # Get the content of exactly one child element of type "elem" of the
        # currently importing element.
        #
        # If elem is set to :self, this will give the content of the current element
        def from_element(elem)
          return @current.element.inner_text.strip if(elem == :self)
          elements = all_elements(elem)
          elements = elements.uniq if(elements.size > 1) # Try to ignore dupes
          raise(ArgumentError, "More than one element of #{elem} in #{@current.element.inspect}") if(elements.size > 1)
          elements.first
        end

        # Get the content of all child elements of type "elem" of the currently
        # importing element
        def all_elements(elem)
          result = []
          @current.element.search("/#{elem}").each { |el| result << el.inner_text.strip }
          result
        end
        
        # Get the iso8601 string for the date
        def to_iso8601(date)
          return nil unless(date)
          date = DateTime.parse(date) unless(date.respond_to?(:strftime))
          date.strftime('%Y-%m-%dT%H:%M:%SZ')
        end
        
        # Parses the given string and returns it as a date object
        def parse_date(date, fmt = nil)
          return nil if(date.blank?)
          return DateTime.strptime(date, fmt) if(fmt) # format given
          return DateTime.new(date.to_i) if(date.size < 5) # this short should be a year
          DateTime.parse(date)
        end
        
      end

    end
  end
end