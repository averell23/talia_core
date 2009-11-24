module TaliaCore
  module ActiveSourceParts
    module Xml

      # Class for creating xml-rdf data
      class RdfBuilder < BaseBuilder

        # Writes a simple "flat" triple. If the object is a string, it will be
        # treated as a "value" while an object (ActiveSource or N::URI) will be treated
        # as a "link"
        def write_triple(subject, predicate, object)
          subject = subject.respond_to?(:uri) ? subject.uri.to_s : subject
          predicate = predicate.respond_to?(:uri) ? predicate : N::URI.new(predicate) 
          @builder.rdf :Description, "rdf:about" => subject do
            write_predicate(predicate, [ object ])
          end
        end

        # Writes a complete source to the rdf
        def write_source(source)
          @builder.rdf :Description, 'rdf:about' => source.uri.to_s do # Element describing this resource
            # loop through the predicates
            source.direct_predicates.each do |predicate|
              write_predicate(predicate, source[predicate])
            end
          end
        end

        private 

        # Build the structure for the XML file and pass on to
        # the given block
        def build_structure
          @builder.rdf :RDF, self.class.namespaces do 
            yield
          end
        end


        def self.namespaces
          @namespaces ||= begin
            namespaces = {}
            N::Namespace.shortcuts.each { |key, value| namespaces["xmlns:#{key.to_s}"] = value.to_s }
            namespaces
          end
        end

        # Build an rdf/xml string for one predicate, with the given values
        def write_predicate(predicate, values)
          values.each { |val| write_single_predicate(predicate, val) }
        end # end method

        def write_single_predicate(predicate, value)
          is_property = value.respond_to?(:uri)
          value_properties = is_property ? { 'value' => value } : extract_values(value.to_s)
          value = value_properties.delete('value')
          @builder.tag!(predicate.to_name_s, value_properties) do
            if(is_property)
              @builder.rdf :Description, 'rdf:about' => value.uri.to_s
            else
              @builder.text!(value)
            end
          end
        end

        # Splits up the value, extracting encoded language codes and RDF data types. The 
        # result will be returned as a hash, with the "true" value being "value"
        def extract_values(value)
          prop_string = PropertyString.new(value)
          result = {}
          result['value'] = prop_string
          result['rdf:datatype'] = prop_string.type if(prop_string.type)
          result['xml:lang'] = prop_string.lang if(prop_string.lang)
          
          result
        end
        
      end
    end 
  end
end