module Marten
  class Middleware
    def process_request(request : Marten::HTTP::Request) : Marten::HTTP::Response?
    end

    def process_response(request : Marten::HTTP::Request, response : Marten::HTTP::Response) : Marten::HTTP::Response
      response
    end
  end
end
