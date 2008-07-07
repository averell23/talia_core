require 'active_source/rdf'

module TaliaCore
  
  # This class encapsulate the basic "Source" behaviour for an element in the
  # semantic store. This is the baseclass for all things that are represented
  # as an "Resource" (with URL) in the semantic store.
  class ActiveSource < ActiveRecord::Base
    
    # Relations where this source is the subject of the triple
    has_many_polymorphs :objects, :from => [:active_sources, :semantic_properties],
      :as => :subject, :through => :semantic_relations, :namespace => :talia_core,
      :skip_duplicates => false
    has_many :semantic_relations, :foreign_key => 'subject_id', :class_name => 'TaliaCore::SemanticRelation'
           
    # Relations where this source is the object of the relation
    has_many :related_subjects,
             :foreign_key => 'object_id',
             :class_name => 'TaliaCore::SemanticRelation'
    has_many :subjects, :through => :related_subjects
    
    validates_format_of :uri, :with => /\A\S*:.*\Z/
    validates_uniqueness_of :uri
    
    
    # This will work in the normal way for database attributes. If the value
    # is not an attribute, it tries to find objects related to this source
    # with the value as a predicate URL and returns a collection of those.
    #
    # The assignment operator remains as it is for the ActiveRecord.
    def [](attribute)
      if(attribute_names.include?(attribute.to_s))
        super(attribute)
      else
        raise(ActiveRecord::RecordNotSaved, "No properties on unsaved record.") if(new_record?)
        get_objects_on(attribute)
      end
    end
    
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
      inverseobj = Object.new
      inverseobj.instance_variable_set(:@assoc_source, self)
      
      class << inverseobj     
        
        def [](property)
          @assoc_source.subjects.find(:all, :conditions => { 'semantic_relations.predicate_uri' => property.to_s } )
        end
        
        private :type
      end
      
      inverseobj
    end
    
    # Accessor that allows to lookup a namespace/name combination. This works like
    # the [] method: I will return an array-like object on predicates can be
    # manipulated.
    def predicate(namespace, name)
      namesp_uri = N::Namespace[namespace]
      raise(ArgumentError, "Illegal namespace given #{namespace}") unless(namesp_uri)
      namesp_uri ? get_objects_on(namesp_uri + name.to_s) : nil
    end
    
    # Setter method for predicates by namespace/name combination. This will 
    # *add a precdicate triple, not replace one!*
    def predicate_set(namespace, name, value)
      predicate(namespace, name) << value
    end
    
    # Gets the direct predicates (using the database)
    def direct_predicates
      rels = SemanticRelation.find_by_sql("SELECT DISTINCT predicate_uri FROM semantic_relations WHERE subject_id = #{self.id}")
      rels.collect { |rel| N::Predicate.new(rel.predicate_uri) }
    end
    
    # Gets the inverse predicates
    def inverse_predicates
      rels = SemanticRelation.find_by_sql("SELECT DISTINCT predicate_uri FROM semantic_relations WHERE object_id = #{self.id}")
      rels.collect { |rel| N::Predicate.new(rel.predicate_uri) }
    end
    
    # Gets the types
    def types
      get_objects_on(N::RDF.type.to_s, { :object_type => 'TaliaCore::ActiveSource'}, TypesWrapper)
    end
    
    private
    
    # Returns the related objects on the given predicate, adding the additional
    # conditions to the query.
    def get_objects_on(predicate, conditions = {}, wrapper = SemanticCollectionWrapper)
      conditions.merge!( :predicate_uri => predicate.to_s )
      obs = objects.find(:all, :conditions => conditions )
      wrapper.new(obs, self, predicate)
    end
    
  end
  
end
