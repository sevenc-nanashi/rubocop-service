# frozen_string_literal: true

module RuboCop
  module Server
    class Core
      private

      def demonize
        Cache.write_port_and_token_files(port: @server.addr[1], token: token)

        Cache.write_pid_file do
          print "rubocop-service-nonce:#{ENV.fetch("RUBOCOP_SERVICE_STARTING_NONCE", "")}"
          $stdout.flush
          read_socket(@server.accept) until @server.closed?
        end
      end
    end
  end
end
