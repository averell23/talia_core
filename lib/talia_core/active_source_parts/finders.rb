module TaliaCore
  module ActiveSourceParts

    # All class methods that are used for finding sources.
    module Finders


      # Finder also accepts uris as "ids". There are also some additional options
      # that are accepted:
      # 
      # [*:find_through*] accepts and array with an predicate name and an object
      #                   value/uri, to search for predicates that match the given predicate/value 
      #                   combination
      # [*:type*] specifically looks for sources with the given type.
      # [*:find_through_inv*] like :find_through, but for the "inverse" lookup
      # [*:prefetch_relations*] if set to "true", this will pre-load all semantic
      #                         relations for the sources (experimental, not fully implemented yet)
      def find(*args)
        prefetching = false
        if(args.last.is_a?(Hash))
          options = args.last
          prefetching =  options.delete(:prefetch_relations)
          if(options.empty?) # If empty we remove the args hash, so that the 1-param uri search works
            args.pop
          else
            prepare_options!(args.last)
          end
        end
        result = if(args.size == 1 && (uri_s = uri_string_for(args[0])))
          src = super(:first, :conditions => { :uri => uri_s })
          raise(ActiveRecord::RecordNotFound, "Not found: #{uri_s}") unless(src)
          src
        else
          super
        end

        prefetch_relations_for(result) if(prefetching)

        result
      end

      # Find a list of sources which contains the given token inside the local name.
      # This means that the namespace it will be excluded.
      #
      #   Sources in system:
      #     * http://talia.org/one
      #     * http://talia.org/two
      #
      #   Source.find_by_uri_token('a') # => [ ]
      #   Source.find_by_uri_token('o') # => [ 'http://talia.org/one', 'http://talia.org/two' ]
      #
      # NOTE: It internally use a MySQL function, as sql condition, to find the local name of the uri.
      def find_by_uri_token(token, options = {})
        find(:all, { 
          :conditions => [ "LOWER(SUBSTRING_INDEX(uri, '/', -1)) LIKE ?", '%' + token.downcase + '%' ], 
          :order => "uri ASC" }.merge!(options))
      end

      # Find the Sources within the given namespace by a partial local name
      def find_by_partial_local(namespace, local_part, options = {})
        namesp = N::URI[namespace]
        return [] unless(namesp)
        find(:all, { 
          :conditions => [ 'uri LIKE ?', "#{namesp.uri}#{local_part}%" ], 
          :order => "uri ASC"}.merge!(options))
      end

      # Find the fist Source that matches the given URI.
      # It's useful for admin pane, because users visit:
      #   /admin/sources/<source_id>/edit
      # but that information is not enough, since we store
      # into the database the whole reference as URI:
      #   http://localnode.org/av_media_sources/source_id
      def find_by_partial_uri(id, options = {})
        find(:all, { :conditions => ["uri LIKE ?", '%' + id + '%'] }.merge!(options))
      end
      
      private
      
      # Checks if the :find_through option is set. If so, this expects the
      # option to have 2 values: The first representing the URL of the predicate
      # and the second the URL or value that should be matched.
      #
      # An optional third parameter can be used to force an object search on the
      # semantic_properties table (instead of active_sources) - if not present
      # this will be auto-guessed from the "object value", checking if it appears
      # to be an URL or not.
      #
      #   ...find(:find_through => [N::RDF::something, 'value', true]
      def check_for_find_through!(options)
        if(f_through = options.delete(:find_through))
          assit_kind_of(Array, f_through)
          raise(ArgumentError, "Passed non-hash conditions with :find_through") if(options.has_key?(:conditions) && !options[:conditions].is_a?(Hash))
          raise(ArgumentError, "Cannot pass custom join conditions with :find_through") if(options.has_key?(:joins))
          predicate = f_through[0]
          obj_val = f_through[1]
          search_prop = (f_through.size > 2) ? f_through[2] : !(obj_val.to_s =~ /:/)
          options[:joins] = default_joins(!search_prop, search_prop)
          options[:conditions] ||= {}
          options[:conditions]['semantic_relations.predicate_uri'] = predicate.to_s
          if(search_prop)
            options[:conditions]['obj_props.value'] = obj_val.to_s
          else
            options[:conditions]['obj_sources.uri'] = obj_val.to_s
          end
        end
      end

      # Check for the :find_through_inv option. This expects the 2 basic values
      # in the same way as :find_through.
      #
      # find(:find_through_inv => [N::RDF::to_me, my_uri]
      def check_for_find_through_inv!(options)
        if(f_through = options.delete(:find_through_inv))
          assit_kind_of(Array, f_through)
          raise(ArgumentError, "Passed non-hash conditions with :find_through") if(options.has_key?(:conditions) && !options[:conditions].is_a?(Hash))
          raise(ArgumentError, "Cannot pass custom join conditions with :find_through") if(options.has_key?(:joins))
          options[:joins] = default_inv_joins
          options[:conditions] ||= {}
          options[:conditions]['semantic_relations.predicate_uri'] = f_through[0].to_s
          options[:conditions]['sub_sources.uri'] = f_through[1].to_s
        end
      end


      # Checks for the :type option in the find options. This is the same as
      # doing a :find_through on the rdf type
      def check_for_type_find!(options)
        if(f_type = options.delete(:type))
          options[:find_through] = [N::RDF::type, f_type.to_s, false]
          check_for_find_through!(options)
        end
      end
      
      # Takes the "advanced" options that can be passed to the find method and
      # converts them into "standard" find options.
      def prepare_options!(options)
        check_for_find_through!(options)
        check_for_type_find!(options)
        check_for_find_through_inv!(options)
      end

    end
  end
end