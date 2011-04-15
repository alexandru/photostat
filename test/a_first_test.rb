require 'test/unit'
require 'flickrcli'

class MyFirstTest < Test::Unit::TestCase
  def test_for_truth
    assert_equal FlickrCLI::VERSION, '0.1'
  end  
end
