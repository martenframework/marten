require "./spec_helper"

describe Marten::Template::Condition::Token::Operator do
  describe "::for" do
    it "returns the token corresponding to the passed literal operator" do
      Marten::Template::Condition::Token::Operator.for("||").should eq Marten::Template::Condition::Token::Operator::Or
      Marten::Template::Condition::Token::Operator.for("&&").should eq Marten::Template::Condition::Token::Operator::And
    end

    it "returns nil if the passed literal operator does not correspond to any existing token" do
      Marten::Template::Condition::Token::Operator.for(":-)").should be_nil
    end
  end
end
