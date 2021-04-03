require "./spec_helper"

describe Marten::Template::Parser::Token do
  describe "#type" do
    it "returns the token type" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.type.should eq Marten::Template::Parser::TokenType::TAG
    end
  end

  describe "#content" do
    it "returns the token content" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.content.should eq "for"
    end
  end

  describe "#line_number" do
    it "returns the token line number" do
      token = Marten::Template::Parser::Token.new(Marten::Template::Parser::TokenType::TAG, "for", 1)
      token.line_number.should eq 1
    end
  end
end
