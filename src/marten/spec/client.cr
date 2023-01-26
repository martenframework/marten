module Marten
  module Spec
    # A test client allowing to issue requests to the server and obtain the associated responses.
    #
    # By leveraging this test client, developers can easily forge various requests and obtain the corresponding
    # responses returned by the server. In the process, the test client ensures that all the configured middlewares are
    # used and applied.
    #
    # It should be noted that a test client is stateful: cookies and session data will be retained for the lifetime of
    # a specific client instance.
    #
    # Moreover, the test client disables CSRF checks by default in order to ease the process of testing unsafe request
    # methods. If you trully need to have these checks applied when running specs, you can initialize a test client by
    # setting `disable_request_forgery_protection` to `false`.
    class Client
      @server_handler : ::HTTP::Handler?
      @session : HTTP::Session::Store::Base?

      # Returns a `Marten::HTTP::Headers` object that can be leveraged to set headers that should bet for each request.
      getter headers

      def initialize(@content_type : String? = nil, @disable_request_forgery_protection = true)
        @headers = HTTP::Headers.new
      end

      # Returns a `Marten::HTTP::Cookies` object that can be leveraged to set cookies that should be used by the client.
      #
      # Cookies that are defined via this hash-like object will automatically be used for every request issued by the
      # test client.
      def cookies
        @cookies ||= Marten::HTTP::Cookies.new
      end

      # Allows to issue a DELETE request to the server.
      def delete(
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "DELETE",
          path: path,
          data: data,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue a GET request to the server.
      def get(
        path : String,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "GET",
          path: path,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue a HEAD request to the server.
      def head(
        path : String,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      )
        perform_request(
          method: "HEAD",
          path: path,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue an OPTIONS request to the server.
      def options(
        path : String,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      )
        perform_request(
          method: "OPTIONS",
          path: path,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue a PATCH request to the server.
      def patch(
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "PATCH",
          path: path,
          data: data,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue a POST request to the server.
      def post(
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "POST",
          path: path,
          data: data,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Allows to issue a PUT request to the server.
      def put(
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "PUT",
          path: path,
          data: data,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      # Returns a session store object for the client.
      #
      # This method returns a session store object, initialized using the currently configured session store. The test
      # client will ensure that this session store is automatically saved and that the session key is persisted in the
      # cookies before issuing requests.
      def session
        @session ||= get_session
      end

      # Allows to issue a TRACE request to the server.
      def trace(
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      ) : Marten::HTTP::Response
        perform_request(
          method: "TRACE",
          path: path,
          data: data,
          query_params: query_params,
          content_type: content_type,
          headers: headers,
          secure: secure
        )
      end

      private DEFAULT_CONTENT_TYPE_PER_METHOD = {
        "DELETE"  => "application/octet-stream",
        "GET"     => "application/octet-stream",
        "OPTIONS" => "application/octet-stream",
        "PATCH"   => "application/octet-stream",
        "POST"    => "#{MULTIPART_CONTENT_TYPE_PREFIX} boundary=#{MULTIPART_BOUNDARY}",
        "PUT"     => "application/octet-stream",
      }

      private MULTIPART_BOUNDARY            = "B0UnDaRyUnIqU3"
      private MULTIPART_CONTENT_TYPE_PREFIX = "multipart/form-data;"
      private MULTIPART_CONTENT_TYPE        = "#{MULTIPART_CONTENT_TYPE_PREFIX} boundary=#{MULTIPART_BOUNDARY}"

      private SERVER_HANDLER_CHAIN = [
        Server::Handlers::Middleware,
        Server::Handlers::Routing,
      ]

      private URL_ENCODED_FORM_CONTENT_TYPE = "application/x-www-form-urlencoded"

      private getter? disable_request_forgery_protection

      private def build_multipart_body(data)
        io = IO::Memory.new

        ::HTTP::FormData.build(io, MULTIPART_BOUNDARY) do |builder|
          data.each do |key, value|
            case (object = value)
            when Enumerable, Iterable
              object.each { |v| builder.field(key.to_s, v.to_s) }
            when DB::Field::File::File
              builder.file(key.to_s, object.open, ::HTTP::FormData::FileMetadata.new(filename: object.name.to_s))
            when IO
              builder.file(key.to_s, object, ::HTTP::FormData::FileMetadata.new(filename: "file"))
            else
              builder.field(key.to_s, value.to_s)
            end
          end
        end

        io.to_s
      end

      private def build_query_params(raw_query_params)
        query_params = URI::Params.new

        raw_query_params.each do |key, value|
          query_params[key.to_s] = case (object = value)
                                   when Enumerable, Iterable
                                     object.map(&.to_s)
                                   else
                                     [object.to_s]
                                   end
        end

        query_params
      end

      private def default_content_type
        @content_type
      end

      private def get_session : HTTP::Session::Store::Base
        session_store_klass = HTTP::Session::Store.get(Marten.settings.sessions.store)
        session_cookie = cookies[Marten.settings.sessions.cookie_name]?
        return session_store_klass.new(session_cookie) if !session_cookie.nil? && !session_cookie.try(&.empty?)

        session_store = session_store_klass.new(nil)
        session_store.save

        cookies[Marten.settings.sessions.cookie_name] = session_store.session_key

        session_store
      end

      private def perform_request(
        method : String,
        path : String,
        data : Hash | NamedTuple | Nil | String = nil,
        query_params : Hash | NamedTuple | Nil = nil,
        content_type : String? = nil,
        headers : Hash | NamedTuple | Nil = nil,
        secure = false
      )
        request_content_type = content_type || default_content_type || DEFAULT_CONTENT_TYPE_PER_METHOD[method]?
        request_headers = Marten::HTTP::Headers{"Host" => "127.0.0.1"}
        request_headers["Content-Type"] = request_content_type if request_content_type

        @headers.try(&.each { |k, v| request_headers[k.to_s] = v.first.to_s })
        headers.try(&.each { |k, v| request_headers[k.to_s] = v.to_s })

        request_full_path = if query_params.nil?
                              path
                            else
                              "#{path}?#{build_query_params(query_params)}"
                            end

        request_body = case data
                       when Hash, NamedTuple
                         if request_content_type.try(&.starts_with?(MULTIPART_CONTENT_TYPE_PREFIX))
                           build_multipart_body(data)
                         elsif request_content_type == URL_ENCODED_FORM_CONTENT_TYPE
                           build_query_params(data).to_s
                         end
                       else
                         data
                       end

        context = ::HTTP::Server::Context.new(
          request: ::HTTP::Request.new(
            method: method,
            resource: request_full_path,
            headers: request_headers.to_stdlib,
            body: request_body
          ),
          response: ::HTTP::Server::Response.new(io: IO::Memory.new)
        )

        # Saves the session store (just in case it might not have been saved before) and updates the session ID value in
        # the cookies.
        if session?
          session.save
          cookies[Marten.settings.sessions.cookie_name] = session.session_key
        end

        # Sets the cookies that might have been set on the client before performing the actual request.
        cookies.to_stdlib.each { |c| context.request.cookies << c }

        # Disables CSRF checks and sets the request to secure if applicable.
        context.marten.request.disable_request_forgery_protection = true if disable_request_forgery_protection?
        context.marten.request.scheme = "https" if secure

        server_handler.call(context)
        response = context.marten.response.not_nil!

        # Updates the cookies store and resets the session store from the obtained response.
        @cookies = HTTP::Cookies.new(context.response.cookies)
        @session = nil

        response
      end

      private def session?
        !@session.nil?
      end

      private def server_handler
        @server_handler ||= ::HTTP::Server.build_middleware(SERVER_HANDLER_CHAIN.map(&.new))
      end
    end
  end
end
