# Copyright (c) 2010 Net7 SRL, <http://www.netseven.it/>
# This Software is released under the terms of the MIT License
# See LICENSE.TXT for the full text of the license.

require File.join(File.dirname(__FILE__), '..', 'test_helper')
require File.join(File.dirname(__FILE__), '..', '..', 'lib', 'core_ext', 'string')

class StringTest < Test::Unit::TestCase
  def test_to_permalink
    assert_equal('Should_Strip_All_Non_Word_Chars', 'should strip *all* non-word chars!'.to_permalink)
    assert_equal('Should_Strip_White_Spaces', 'should strip    white    spaces'.to_permalink)
    assert_equal('Should_Titleize_Mixed_Case_Strings', 'sHoULD tItLEIzE mIxEd cAsE sTrINgS'.to_permalink)
    assert_equal('Should_Replace_Spaces_With_Underscores', 'should replace spaces with underscores'.to_permalink)
  end
  
  def test_to_uri
    assert_equal(N::URI.new('http://foo-foo.com'), 'http://foo-foo.com'.to_uri)
    assert_kind_of(N::URI, 'foo-foo.com'.to_uri)
  end
  
  def test_yes
    assert(" YeS ".yes?)
    assert("TRUE".yes?)
  end
  
  def test_no
    assert("No ".no?)
    assert("false".no?)
  end
  
end
