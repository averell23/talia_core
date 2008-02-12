require 'test/unit'
require 'rexml/document'


# Load the helper class
require File.join(File.dirname(__FILE__), 'util_helper')

# require util stuff
require 'talia_util'

module TaliaUtil

  # Test te DataRecord storage class
  class EditionImportTest < Test::Unit::TestCase
  
    include UtilTestMethods
    
    # Establish the database connection for the test
    TaliaCore::TestHelper.startup
    
    
    # Flush RDF before each test
    def setup
      setup_once(:src) do
        TaliaCore::TestHelper.flush_rdf
        TaliaCore::TestHelper.flush_db
        HyperImporter::Importer.import(load_doc('essay'))
      end
    end
    
    # Test if the import succeeds
    def test_import
      assert_kind_of(TaliaCore::Source, @src)
    end
    
    # Test if the types were imported correctly
    def test_types
      assert_types(@src, N::HYPER + "Essay", N::HYPER + "PDF")
    end
    
    # Test the title property
    def test_title
      assert_property(@src.dcns::title, "Féré et Nietzsche : au sujet de la décadence")
    end
    
    # Test source name
    def test_siglum
      assert_equal(N::LOCAL + "jgrzelczyk-4", @src.uri)
    end
    
    # Test the publishing date
    def test_pubdate
      assert_property(@src.dcns::date, "2005-11-01")
    end
    
    # Test the publisher
    def test_publisher
      assert_property(@src.dcns::publisher, "HyperNietzsche")
    end

    # Test if the curator was imported correctly
    def test_curator
      assert_property(@src.hyper::curator, N::LOCAL::jgrzelczyk)
    end

    # And now: already_published
    def test_already_published
      assert_property(@src.hyper::already_published, "yes")
    end
    
    # Test the language setting
    def test_language
      assert_property(@src.dcns::language, "fr")
    end
    
  end
end
