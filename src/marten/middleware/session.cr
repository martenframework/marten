module Marten
  abstract class Middleware
    # Enables the use of sessions.
    #
    # When this middleware is used, each request will have a session store initialized according to the sessions
    # configuration. This session store is a hash-like object that allows to fetch or set values that are associated
    # with specific keys.
    #
    # The session store is initialized from a session key that is stored as a regular cookie. If the session store ends
    # up being empty after a request's handling, the associated cookie is deleted. Otherwise if the session store is
    # modified as part of the considered request the associated cookie is refreshed. Each session cookie is set to
    # expire according to a configured cookie max age (the default cookie max age is 2 weeks).
    class Session < Middleware
      def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
        setup_session(request)

        response = get_response.call

        persist_session(request, response)
        response
      end

      private def persist_session(request, response)
        session_accessed = request.session.accessed?
        session_modified = request.session.modified?

        if request.cookies.has_key?(Marten.settings.sessions.cookie_name) && request.session.empty?
          request.cookies.delete(
            Marten.settings.sessions.cookie_name,
            domain: Marten.settings.sessions.cookie_domain,
            same_site: Marten.settings.sessions.cookie_same_site
          )
          response.headers.patch_vary("Cookie")
          return
        end

        if session_accessed
          response.headers.patch_vary("Cookie")
        end

        return unless session_modified
        return unless response.status != 500

        request.session.save

        response.cookies.set(
          Marten.settings.sessions.cookie_name,
          request.session.session_key.not_nil!,
          expires: Time.local + Time::Span.new(seconds: Marten.settings.sessions.cookie_max_age),
          domain: Marten.settings.sessions.cookie_domain,
          secure: Marten.settings.sessions.cookie_secure,
          http_only: Marten.settings.sessions.cookie_http_only,
          same_site: Marten.settings.sessions.cookie_same_site
        )
      end

      private def setup_session(request)
        session_store_klass = HTTP::Session::Store.get(Marten.settings.sessions.store)
        request.session = session_store_klass.new(request.cookies[Marten.settings.sessions.cookie_name]?)
      end
    end
  end
end
