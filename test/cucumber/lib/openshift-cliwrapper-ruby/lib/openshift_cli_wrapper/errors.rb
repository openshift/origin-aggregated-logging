module OpenshiftCliWrapper
    module Errors
        class AuthorizationError < RuntimeError

            def initialize(msg)
                super(msg)
            end
        end
    end
end
