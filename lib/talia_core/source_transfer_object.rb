# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

module TaliaCore #:nodoc:
  # Transfer Object Pattern implementation.
  # It's required by source administration panel, in order to normalize
  # the values transportation between view and controller layers.
  #
  # RDF objects (triple endpoint), could be a Source or a String.
  #
  # http://java.sun.com/blueprints/corej2eepatterns/Patterns/TransferObject.html
  # http://java.sun.com/blueprints/patterns/TransferObject.html
  #
  # TODO: Remove as part of old admin interface?
  class SourceTransferObject # :nodoc:
    attr_reader :uri
    
    def initialize(name_or_uri) #:nodoc:
      @uri, @name = if /http:\/\//.match name_or_uri
        uri = N::URI.new(name_or_uri)
        [uri, uri.local_name]
      else
        [nil, name_or_uri]
      end
    end
    
    def id
      @name
    end
    
    def source?
      !uri.blank?
    end
    
    def titleized #:nodoc:
      @name.titleize
    end
    
    def to_s #:nodoc:
      (uri || @name).to_s
    end
  end
end
