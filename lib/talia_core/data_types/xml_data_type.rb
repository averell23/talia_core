require 'talia_core/local_store/data_record'
require "rexml/document"

module TaliaCore
  
  # Class to manage XML and HTML data type
  class XmlDataType < DataRecord
    
    # include the module to work with files
    # TODO: paramterize this. If we'll have to work with file inculde the following
    #       otherwise, include the database mixin
    include FileStore

    # return the mime_type for this specified class
    def mime_type
      case File.extname(get_file_path)
      when '.htm', '.html','.xhtml'
        'text/html'
      when '.hnml'
        'text/hnml'
      when '.xml'
        'text/xml'
      end
    end
    
    # return the mime subtype for this specified class
    def mime_subtype
      mime_type.split(/\//)[1]
    end    
    
    # returns all bytes in the object as an array
    def all_bytes
      read_all_bytes
    end
    
    # returns the complete text
    def all_text
      if(!is_file_open?)
        open_file
      end
      @file_handle.read(self.size)
    end

    # returns the next byte from the object, or nil at EOS
    def get_byte(close_after_single_read=false)
      get_next_byte(close_after_single_read)
    end

    # returns the current position of the read cursor (binary access)
    def position
      return (@position != nil) ? @position : 0
    end
   
    # reset the cursor to the initial state
    def reset
      set_position(0)
    end
    
    # set the new position of the reding cursors
    def seek(new_position)
      set_position(new_position)
    end
    
    # returns the size of the object in bytes
    def size
      get_data_size
    end
    
    # Additional methods for this specific class ====================================

    # return contect of the object as REXML::Elements
    def get_content(options = nil)
      document = REXML::Document.new all_text
      
      # get content
      if mime_subtype == "html"
        content = document.elements['//body'].elements
      elsif ((mime_subtype == "xml") or (mime_subtype == "hnml"))
        content = document.root.elements
      end
      
      # return content
      return content
    end
    
  end
end
