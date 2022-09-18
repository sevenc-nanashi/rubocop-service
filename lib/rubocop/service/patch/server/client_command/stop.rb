# frozen_string_literal: true

module RuboCop
  module Server
    module ClientCommand
      # This class is a client command to stop server process.
      # @api private
      class Stop < Base
        def run
          return unless check_running_server

          send_request(command: "stop")
          Server.wait_for_running_status!(false)
        end
      end
    end
  end
end
