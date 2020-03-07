module Blog
  module Views
    class Home < Marten::Views::Base
      def get(request, *args, **kwargs)
        Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200)
      end
    end
  end
end
