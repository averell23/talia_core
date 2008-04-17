require 'test/unit'

# Load the helper class
require File.join(File.dirname(__FILE__), 'util_helper')

# require util stuff
require 'talia_util'

module TaliaUtil

  # Test te DataRecord storage class
  class PathStepImportTest < Test::Unit::TestCase
  
    include UtilTestMethods
    
    # Establish the database connection for the test
    TaliaCore::TestHelper.startup
    
    
    # Flush RDF before each test
    def setup
      setup_once(:flush) do
        clean_data_files
        TaliaCore::TestHelper.flush_rdf
        TaliaCore::TestHelper.flush_db
      end
      setup_once(:src) do
        HyperImporter::Importer.import(load_doc('igerike-927,1'))
      end
    end
    
    # Test if the import succeeds
    def test_import
      assert_kind_of(TaliaCore::Source, @src)
    end
    
        # Test source name
    def test_siglum
      assert_equal(N::LOCAL + "igerike-927,1", @src.uri)
    end
    
    # Test if the types were imported correctly
    def test_types
      assert_types(@src, N::HYPER.PathStep)
    end
    
    # Test the ordering
    def test_ordering
      assert_property(@src.hyper::position, "1")
    end
    
    # Test the description field
    def test_description
      # Useless, but didn't seem to find one with description
      assert_equal(0, @src.dcns::description.size)
    end
    
    def test_part_of
      assert_property(@src.hyper::part_of, N::LOCAL + 'igerike-927')
    end
    
    def related_document
      assert_property(@src.hyper::cites, N::LOCAL + 'N-IV-1,17[2]')
    end
    
  end
end
