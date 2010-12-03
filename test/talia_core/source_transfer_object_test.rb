# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

require 'test/unit'
require File.join(File.dirname(__FILE__), '..', 'test_helper')

module TaliaCore
  class SourceTransferObjectTest < Test::Unit::TestCase
    def test_with_uri
      s = SourceTransferObject.new("#{N::LOCAL}Homer_Simpson")
      assert_equal('Homer Simpson', s.titleized)
      assert_equal('Homer_Simpson', s.id)
      assert_equal("#{N::LOCAL}Homer_Simpson", s.to_s)
      assert_equal("#{N::LOCAL}Homer_Simpson", s.uri.to_s)
      assert s.source?
    end
    
    def test_with_string
      s = SourceTransferObject.new('Homer Simpson')
      assert_equal('Homer Simpson', s.titleized)
      assert_equal('Homer Simpson', s.to_s)
      assert_equal('Homer Simpson', s.id)
      assert_nil(s.uri)
      assert_not s.source?
    end
  end
end
