require File.join(File.dirname(__FILE__), "..", "..", "test_helper")

require 'mocha/parameter_matchers/has_key'
require 'mocha/inspect'

class HasKeyTest < Test::Unit::TestCase
  
  include Mocha::ParameterMatchers
  
  def test_should_match_hash_including_specified_key
    matcher = has_key(:key_1)
    assert matcher == { :key_1 => 1, :key_2 => 2 }
  end
  
  def test_should_not_match_hash_not_including_specified_key
    matcher = has_key(:key_1)
    assert matcher != { :key_2 => 2 }
  end
  
  def test_should_describe_matcher
    matcher = has_key(:key)
    assert_equal 'has_key(:key)', matcher.mocha_inspect
  end
  
end