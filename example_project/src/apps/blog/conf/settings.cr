module Blog
  module Conf
    class Settings < Marten::Conf::Settings
      namespace :blog

      def initialize
        @foo = ""
      end

      def foo
        @foo
      end

      def foo=(value)
        @foo = value
      end
    end
  end
end
