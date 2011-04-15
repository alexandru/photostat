require 'minitest/spec'
require 'test/unit'
require 'photostat'


describe Photostat do
  describe "when asked about version" do
    it "should say 1.0" do
      Photostat::VERSION.must_equal '0.1'
    end
  end

  describe "when no params are given" do
    it "should give me an error with available commands" do
      Photostat.run([])
    end
  end
end



