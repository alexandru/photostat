module Photostat
  module WebApp
    module Racks

      class Thumbnailer
        def initialize(size)          
          @size = size
        end

        def call(env)
          [200, {"Content-Type" => "text/html"}, env.to_s]
        end
      end

    end
  end
end
