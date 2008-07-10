require 'test/unit'
require 'talia_core/data_types/xml_data'

# Load the helper class
require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

module TaliaCore

  # Test te DataRecord storage class
  class XmlDataTest < Test::Unit::TestCase
    
    fixtures :source_records, :data_records
     
    def setup
      # Sets the file that is used by one test
      setup_once(:tmp_file) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data_for_test', 'XmlData', 'temp0.xhtml')) }
      setup_once(:flush) do
        # If the temp file already exists, it must be deleted
        File.delete(@tmp_file) if(File.exist?(@tmp_file))
        true
      end
      @test_records = DataRecord.find_data_records(1)
    end
    
    # test not nil and records numbers
    def test_records_numbers
      assert_not_equal [], @test_records
      assert_equal 13, @test_records.size
    end
  
    # test class type and mime_type and subtype
    def test_mime_types
      assert_kind_of(XmlData, @test_records[2])
      assert_kind_of(XmlData, @test_records[3])
      assert_kind_of(XmlData, @test_records[4])
      assert_kind_of(XmlData, @test_records[5])
      assert_kind_of(XmlData, @test_records[6])
      assert_equal("text/xml", @test_records[2].mime_type)
      assert_equal("xml", @test_records[2].mime_subtype)
      assert_equal("text/html", @test_records[3].mime_type)
      assert_equal("html", @test_records[3].mime_subtype)
      assert_equal("text/hnml", @test_records[4].mime_type)
      assert_equal("hnml", @test_records[4].mime_subtype)
      assert_equal("text/html", @test_records[5].mime_type)
      assert_equal("html", @test_records[5].mime_subtype)
      assert_equal("text/html", @test_records[6].mime_type)
      assert_equal("html", @test_records[6].mime_subtype)
    end
    
    # test data directory
    def test_data_directory
      dir_for_test  = File.expand_path(@test_records[2].data_directory)
      assert_equal(base_dir_name(@test_records[2].id), dir_for_test)
      assert(File.exists?(dir_for_test))
      assert_equal(File.join(base_dir_name(@test_records[2].id), 'temp1.xml'), File.join(dir_for_test, @test_records[2].location))
      assert( File.exists?(File.join(dir_for_test, @test_records[2].id.to_s + File.extname(@test_records[2].location))), "#{File.join(dir_for_test, @test_records[2].location)} does not exist" )
    end

    # test file size
    def test_file_size
      assert_equal(300, @test_records[2].size)
    end
    
    # test binary access
    def test_binary_access
      # Check initial position
      assert_equal(0, @test_records[2].position)
      
      # Try to read all bytes
      bytes = @test_records[2].all_bytes
      assert_equal(300, bytes.size)
      assert_equal(false, @test_records[2].is_file_open?)

      
      # Re-check position (it should be 0)
      assert_equal(0, @test_records[2].position)
      
      # Read only one bytes and check position
      byte = @test_records[2].get_byte
      # check byte by code (60 == '<')
      assert_equal(60, byte)
      # Re-check position (it should be 1)
      assert_equal(1, @test_records[2].position)
    end
    
    # test for specific classes methods
    def test_specific_classes_methods
      # test content value
      xml_content =  @test_records[2].get_content
      xhtml_content = @test_records[3].get_content
      hnml_content = @test_records[4].get_content
      
      assert_kind_of REXML::Elements, xml_content
      assert_not_equal nil, xml_content.nil?
      
      assert_kind_of REXML::Elements, xhtml_content
      assert_not_equal nil, xhtml_content.nil?
      
      assert_kind_of REXML::Elements, hnml_content
      assert_not_equal nil, hnml_content.nil?
      
      # test Tidy parsing
      new_record = TaliaCore::XmlData.new
      new_record.source_record_id = TaliaCore::Source.find(:first).id
      new_record.create_from_data('test_file.xhtml', @test_records[5].all_text, {:tidy => true})
      new_record.save!
      # read data from file
      string_tidy = new_record.all_text
      # if tidy is enabled, check tidy output
      if !ENV['TIDYLIB'].nil?
        assert_equal string_tidy, @test_records[6].all_text
      end
    end
    
    private
    def base_dir_name(id=nil)
      @data_path_test ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'data_for_test', 'XmlData', ("00" + id.to_s)[-3..-1]))
    end
  end
   
end

