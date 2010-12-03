# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

require File.join(File.dirname(__FILE__), '..', 'test_helper')

module TaliaCore
  # Test the RdfReader class.
  class NtriplesReaderTest < Test::Unit::TestCase

    suppress_fixtures
    
    def setup
      setup_once(:sources) {ActiveSourceParts::Rdf::NtriplesReader.sources_from_url(TestHelper.fixture_file('rdf_test.nt'))}
      @source = @sources.detect {|el| el['uri'] == 'http://foodonga.com'}
    end

    def test_sources
      assert_equal(2, @sources.size)
    end
    
    def test_attributes
      assert_kind_of(Hash, @source)
    end
    
    def test_uri
      assert_equal('http://foodonga.com', @source['uri'])
    end
    
    def test_predicate
      assert_equal(['foo', 'bar', '<http://bingobongo.com>'], @source['http://bongobongo.com'])
    end
    
    def test_i18n_value
      assert_equal('en', @source['http://bongobongo.com'].detect {|el| el == 'bar'}.lang)
    end
    
    def test_type
      assert_equal('TaliaCore::Collection', @source['type'])
    end
    
    # Test if everything has a type (otherwise there will be DummySources created)
    def test_have_types
      @sources.each { |s| assert(!s['type'].blank?, "No type for #{s['uri']}") }
    end

    def test_rdf_type
      # While we know that we will have only one value for rdf type, remember that 
      # rdf type can actually be an array of values.
       assert_not_nil(@source[N::RDF.type.to_s].detect {|el| el == "<#{N::SKOS.Collection.to_s}>"})
    end
  end
end
