require 'test/unit'

# Load the helper class
require File.join(File.dirname(__FILE__), 'util_helper')

# require util stuff
require 'talia_util'

module TaliaUtil

  # Test te DataRecord storage class
  class AutorImportTest < Test::Unit::TestCase
  
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
        hyper_import(load_doc('pdiorio'))
      end
    end
    
    # Test if the import succeeds
    def test_import
      assert_kind_of(TaliaCore::Source, @src)
    end
    
        # Test source name
    def test_siglum
      assert_equal(N::LOCAL + "pdiorio", @src.uri)
    end
    
    # Test if the types were imported correctly
    def test_types
      assert_types(@src, N::HYPER.Author)
    end
    
    # Test the ordering
    def test_name
      assert_property(@src.hyper::author_name, "Paolo")
    end
    
    def test_surname
      assert_property(@src.hyper::author_surname, "D'Iorio")
    end
    
    def test_status
      assert_property(@src.hyper::author_status, "member")
    end
    
    def test_institution
      assert_property(@src.hyper::author_institution, "ITEM - CNRS/ENS")
    end
    
    def test_position
      assert_property(@src.hyper::author_position)
    end
    
    def test_address
      assert_property(@src.hyper::address)
    end
    
    def test_zip
      assert_property(@src.hyper::zip, 'F-75005')
    end
    
    def test_city
      assert_property(@src.hyper::city, 'Paris')
    end
    
    def test_state
      assert_property(@src.hyper::country, "France")
    end
    
    def test_phone
      assert_property(@src.hyper::phone, "+33-144321884")
    end
    
    def test_fax
      assert_property(@src.hyper::fax, "+33-144321890")
    end
    
    def test_email
      assert_property(@src.hyper::email, "diorio@ens.fr")
    end
    
    def test_webpage
      assert_property(@src.hyper::webpage)
    end
    
    def test_from_date
      assert_property(@src.hyper::from_date, "2003-11-09")
    end
    
    def test_to_date
      assert_property(@src.hyper::to_date)
    end
    
    
    

  end
end