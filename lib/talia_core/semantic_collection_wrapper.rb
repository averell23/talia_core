module TaliaCore

  # Wraps the Array/Collection returned from the ActiveRecord, simply 
  # "hiding" the SemanticProperty objects behind strings.
  class SemanticCollectionWrapper

    include Enumerable

    attr_reader :force_type

    # Simple hash that checks if a type if property requires "special" handling
    # This will cause the wrapper to accept ActiveSource relations and all
    # sources will be casted to the given type
    def self.special_types
      @special_types ||= {
        N::RDF.type.to_s => N::SourceClass
      }
    end

    # Initialize the list
    def initialize(source, predicate)
      # raise(ActiveRecord::RecordNotSaved, "No properties on unsaved record.") if(source.new_record?)
      @assoc_source = source
      @assoc_predicate = if(predicate.respond_to?(:uri))
        predicate.uri.to_s
      else
        predicate.to_s
      end
      @force_type = self.class.special_types[@assoc_predicate]
    end

    # Get the element '''value''' at the given index
    def at(index)
      items.at(index).value if(items.at(index))
    end
    alias :[] :at

    def first
      item = items.first
      item ? item.value : nil
    end

    def last
      item = items.last
      item ? item.value : nil
    end

    # Gets the value at the given index
    def get_item_at(index)
      items.at(index).object if(items.at(index))
    end

    # Iterates over each '''value''' of the items in the relation.
    def each
      items.each { |item| yield(item.value) }
    end

    # Collect method for the semantic wrapper
    def collect
      items.collect { |item| yield(item.value) }
    end

    # Iterates of each '''target''' of the items in the relation. (This
    # will pass in SemanticProperty objects instead of the value
    def each_item
      items.each { |item| yield(item.object) }
    end

    # Returns an array with all values in the collection
    def values
      items.collect { |item| item.value }
    end

    # Returns only the values of the given language.
    # (At the moment this is not aware of region codes or any
    # specialities, it just does a string matching)
    #
    # If no values with the given locale are found, this will
    # fall back on the default locale and then to the values
    # that don't have a locale at all.
    def values_with_lang(language = 'en')
      language_is_default = (language == I18n.default_locale.to_s)
      real = []
      default = []
      unset = []
      items.each do |item|
        # FIXME: At the moment, this only works for value attributes, not for 
        # sources
        if((val = item.value).respond_to?(:lang))
          real << val if(val.lang == language)
          default << val if(!language_is_default && (val.lang == I18n.default_locale.to_s))
          unset << val if(val.lang.blank?)
        else
          default << val
        end
      end
      return real unless(real.empty?)
      return default unless(default.empty?)
      unset
    end
    
    # Size of the collection.
    def size
      return items.size if(loaded?)
      if(@items)
        # This is not really possible without loading, so we do it
        load!
        items.size
      else
        SemanticRelation.count(:conditions => {
          'subject_id' => @assoc_source.id,
          'predicate_uri' => @assoc_predicate })
        end
      end

      # Joins the elments into a string
      def join(join_str = ', ')
        strs = items.collect { |item| item.value.to_s }
        strs.join(join_str)
      end

      # Index of the given value
      def index(value)
        items.index(value)
      end

      # Check if the collection includes the value
      def include?(value)
        items.include?(value)
      end

      # Get the index of the given item

      # Push to collection. Giving a string will create a property to be created,
      # saved and associated.
      def <<(value)
        add_with_order(value, nil)
      end
      alias_method :concat, '<<'

      # Adds the object and gives the relation the given order. 
      def add_with_order(value, order)
        # We use order exclusively for "ordering" predicates
        assit_equal(TaliaCore::Collection.index_to_predicate(order), @assoc_predicate) if(order)
        raise(ArgumentError, "cannot add nil") unless(value != nil)
        if(value.kind_of?(Array))
          value.each { |v| add_record_for(v, order) }
        else
          add_record_for(value, order)
        end
      end

      # Replace a value with a new one
      def replace(old_value, new_value)
        idx = items.index(old_value)
        items[idx].destroy
        add_record_for(new_value) { |new_item| items[idx] = new_item }
      end

      # Remove the given value. With no parameters, the whole list will be
      # cleared and the RDF will be updated immediately.
      def remove(*params)
        if(params.length > 0)
          params.each { |par| remove_relation(par) }
        else
          if(loaded?)
            items.each { |item| item.relation.destroy }
          else
            SemanticRelation.destroy_all(
            :subject_id => @assoc_source.id,
            :predicate_uri => @assoc_predicate
            )
          end
          @assoc_source.my_rdf.remove(@assoc_predicate.to_uri) unless(@assoc_source.uri.to_s.blank?)
          @items = []
          @loaded = true
        end
      end

      # This attempts to save the items to the database
      def save_items!
        return if(clean?) # If there are no items, nothing was modified
        @assoc_source.save! unless(@assoc_source.id)
        @items.each do |item|
          next if(item.fat_relation) # we skip the fat relations, they are never new and never saveable
          rel = item.plain_relation
          must_save = rel.new_record?
          if(rel.object_id.nil?)
            rel.object.save! if(rel.object.new_record?)
            rel.object_id = rel.object.id
            must_save = true
          end
          unless(rel.subject_id != nil)
            rel.subject_id = @assoc_source.id
            must_save = true
          end
          rel.save! if(must_save)
        end
        @items = nil unless(loaded?) # Otherwise we'll have trouble reload-and merging
      end

      # Indicates of the internal collection is loaded
      def loaded?
        @loaded
      end

      # Indicates that the wraper is "clean", that is it hasn't been written to
      # or read from
      def clean?
        @items.nil?
      end

      def empty?
        self.size == 0
      end

      # Injector for a fat relation. This must take place before flagging the
      # source as "loaded"
      def inject_fat_item(fat_rel)
        raise(RuntimeError, 'Trying to inject in loaded object.') if(loaded?)
        @items ||= []
        @items << SemanticCollectionItem.new(fat_rel, :fat)
      end
      
      # Forces this relation to be empty. This initializes the relation
      # as if no elements exist. This doesn't look anything up in the 
      # databse. *Warning* Only call this if you need an empty wrapper
      # that doesn't look up anything in the database
      def init_as_empty!
        raise(ArgumentError, "Already initialized!") if(loaded?)
        @items = []
        @loaded = true
      end

      private

      # Load the current relation. (Loading should be lazy, so that the database
      # is not hit until needed.
      def load!
        # The "fat" relations contain all the data to build the related objects if
        # required
        relations = SemanticRelation.find_fat_relations(@assoc_source, @assoc_predicate)

        init_from_fat_rels(relations)
      end

      # Inject a fat relation into the items
      
      # Inititlizes the collection from the given collection of "fat" relations
      def init_from_fat_rels(fat_relations)
        # Check if there are records that have been added previously
        old_items = @items
        # Create the internal collection
        @items = Array.new(fat_relations.size)
        fat_relations.each_index do |idx|
          rel = SemanticCollectionItem.new(fat_relations.at(idx), :fat)
          @items[idx] = rel
        end
        @items = (@items | old_items) if(old_items)
        @loaded = true
        @items
      end

      # Returns the items in the collection
      def items
        load! unless(loaded?)
        @items
      end

      # Deletes the relation where with the current predicate and the given 
      # value.
      def remove_relation(value)
        idx = items.index(value)
        return unless(idx)
        remove_at(idx)
      end

      # Removes a relation at the given index
      def remove_at(index)
        items.at(index).relation.destroy
        items.delete_at(index)
      end

      # Creates a record for a value and adds it. This will add the given value if it's 
      # a database record and otherwise create a property with the given value.
      # The block can be given when you want to add the new SemanticCollectionItem
      # to the colleciton in a specific way.
      # are loaded.
      def add_record_for(value, order = nil)
        assit_not_nil(value)
        if(@force_type)
          # If we have a type, we must transform the value
          value = value.respond_to?(:uri) ? value.uri : value
          value = ActiveSource.new(value.to_s)
        end

        value = check_for_source(value) if(value.is_a?(ActiveSource))

        rel = create_predicate(value)
        rel.rel_order = order if(order)
        item = SemanticCollectionItem.new(rel, :plain)
        block_given? ? yield(item) : insert_item(item)
      end

      # Insert a new item
      def insert_item(item)
        @items ||= []
        @items << item
      end

      # Write a triple to the store. For normal operation it's recommended that
      # the usual accessor methods are used. This method does less checking
      # and does not accept array objects as value.
      def create_predicate(value)
        # TODO: Semantic Properties should only be created inside, since assigning
        #       one to multiple relations and then deleting breaks integrity.
        #       The whole semantic property should be flattened into a field in
        #       SemanticRelation anyway.
        assit(!value.is_a?(SemanticProperty), "Should not pass in Semantic Properties here!")
        # We need to manually create the relation, to add the predicate_url
        to_add = SemanticRelation.new(
        :subject_id => @assoc_source.id,
        :predicate_uri => @assoc_predicate
        ) # Create a new relation linked to this object

        if(value.is_a?(TaliaCore::ActiveSource) || value.is_a?(TaliaCore::SemanticProperty))
          to_add.object = value
        elsif(value.respond_to?(:uri)) # This appears to refer to a Source. We only add if we can find that source
          to_add.object = TaliaCore::ActiveSource.find(value.uri)
        else
          prop = TaliaCore::SemanticProperty.new
          # Check if we need to add from a PropertyString
          prop.value = value.is_a?(PropertyString) ? value.to_rdf : value
          to_add.object = prop
        end
        to_add
      end



      # This "checks" for the given source. If a source with the same URI has been
      # added to any collection wrapper unsaved
      def check_for_source(source)
        return source unless(source.new_record?)
        cached = unsaved_source_cache[source.uri.to_s]
        if(cached.nil?)
          unsaved_source_cache[source.uri.to_s] = source
          cached = source
        end
        cached
      end

      # Cache for sources that were added as unsaved elements
      def self.unsaved_source_cache
        @unsaved_source_cache ||= {}
      end

      def unsaved_source_cache
        SemanticCollectionWrapper.unsaved_source_cache
      end


    end

  end
