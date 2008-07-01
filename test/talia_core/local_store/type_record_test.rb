require 'test/unit'

# Load the helper class
require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

module TaliaCore
  
  # Test the SourceRecord storage class
  class TypeRecordTest < Test::Unit::TestCase
 
    fixtures :source_records, :type_records
    
    def setup
      @test_record = TypeRecord.new("http://dummyuri.com/")
    end
    
    # Test the accessor methods for uri
    def test_uri
      @test_record.uri = "http://something.com/"
      assert_kind_of(N::SourceClass, @test_record.uri)
      assert_equal("http://something.com/", @test_record.uri.to_s)
    end
    
    # Test if the validation works
    def test_validate
      @test_record.uri = nil
      assert_raise(ActiveRecord::RecordInvalid) { @test_record.save! }
    end
    
  end
end