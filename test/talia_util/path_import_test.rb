require 'test/unit'
require 'rexml/document'


# Load the helper class
require File.join(File.dirname(__FILE__), 'util_helper')

# require util stuff
require 'talia_util'

module TaliaUtil

  # Test te DataRecord storage class
  class PathImportTest < Test::Unit::TestCase
  
    include UtilTestMethods
    
    # Flush RDF before each test
    def setup
      setup_once(:flush) do
        clean_data_files
        Util.flush_rdf
        Util.flush_db
        true
      end
      setup_once(:src) do
        hyper_import(load_doc('igerike-907'))
      end
    end
    
    # Test if the import succeeds
    def test_import
      assert_kind_of(TaliaCore::Source, @src)
    end
    
    # Test if the types were imported correctly
    def test_types
      assert_types(@src, N::HYPER + "Path", N::HYPER + "Genetic")
    end
    
    # Test the title property
    def test_title
      assert_property(@src.dcns::title, "WS-25: Der Tausch und die Billigkeit")
    end
    
    # Test source name
    def test_siglum
      assert_equal(N::LOCAL + "igerike-907", @src.uri)
    end
    
    # Test the publishing date
    def test_pubdate
      assert_property(@src.dcns::date, "2005-01-05")
    end
    
    # Test the publisher
    def test_publisher
      assert_property(@src.dcns::publisher, "HyperNietzsche")
    end

    # Test if the curator was imported correctly
    def test_author
      assert_property(@src.hyper::author, N::LOCAL::igerike)
    end

    # And now: already_published
    def test_already_published
      assert_property(@src.hyper::already_published, "no")
    end
    
    # Test the language setting
    def test_language
      assert_property(@src.dcns::language, "de")
    end
    
    def test_description
      # Useless test, but we found no path to test this with
      assert_equal(0, @src.dcns::description.size)
    end
    
  end
end
