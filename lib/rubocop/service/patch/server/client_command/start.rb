# frozen_string_literal: true

require "pathname"
require "json"
require "rubocop/service/server"

module RuboCop
  module Server
    module ClientCommand
      class Start < Base
        def run
          if Server.running?
            warn "RuboCop server (#{Cache.pid_path.read}) is already running."
            return
          end

          if ENV["RUBOCOP_SERVICE_SERVER_PROCESS"] == "true"
            Cache.acquire_lock do |locked|
              unless locked
                # Another process is already starting server,
                # so wait for it to be ready.
                Server.wait_for_running_status!(true)
                exit 0
              end

              Cache.write_version_file(RuboCop::Version::STRING)

              host = ENV.fetch("RUBOCOP_SERVER_HOST", "127.0.0.1")
              port = ENV.fetch("RUBOCOP_SERVER_PORT", 0)

              Server::Core.new.start(host, port)
            end
          else
            exit_code =
              RuboCop::Service::Server.connect do |connection|
                connection.puts JSON.generate(
                                  { type: :spawn, directory: Dir.pwd }
                                )
              end
            if exit_code.nil?
              warn "\nConnection closed without exit code. Please check the server log: #{File.expand_path("~/.rubocop-service.log")}"
              exit 1
            else
              exit exit_code
            end
          end
        end
      end
    end
  end
end
