require "./spec_helper"

describe Marten::Routing::MatchParameters do
  describe "#[]" do
    it "works with indifferent access" do
      params = Marten::Routing::MatchParameters{"foo" => "bar"}

      params["foo"].should eq "bar"
      params[:foo].should eq "bar"

      expect_raises(KeyError) { params["bar"] }
      expect_raises(KeyError) { params[:bar] }
    end
  end

  describe "#[]?" do
    it "works with indifferent access" do
      params = Marten::Routing::MatchParameters{"foo" => "bar"}

      params["foo"]?.should eq "bar"
      params[:foo]?.should eq "bar"

      params["bar"]?.should be_nil
      params[:bar]?.should be_nil
    end
  end

  describe "#has_key?" do
    it "works with indifferent access" do
      params = Marten::Routing::MatchParameters{"foo" => "bar"}

      params.has_key?("foo").should be_true
      params.has_key?(:foo).should be_true

      params.has_key?("bar").should be_false
      params.has_key?(:bar).should be_false
    end
  end
end
