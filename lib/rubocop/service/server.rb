# frozen_string_literal: true

# -- NOTE --
# This script may be run separately from the library.

require "socket"
require "rubocop"
require "json"
require "win32/service"
require "rbconfig"
require_relative "version"

module RuboCop
  module Service
    module Server
      DEFAULT_SERVER_CONFIG = {
        pid: -1,
        port: -1,
        host: -1,
        version: "0.0.0"
      }.freeze
      SERVICE_NAME = "rubocop_service"

      def initialize
        host = ENV.fetch("RUBOCOP_SERVICE_SERVER_HOST", "127.0.0.1")
        port = ENV.fetch("RUBOCOP_SERVICE_SERVER_PORT", 0)
        @server = TCPServer.open(host, port)
        @threads = []
      end

      def start
        File.write(Server.server_config_path, DEFAULT_SERVER_CONFIG.to_json)

        loop do
          @threads << Thread.start(@server.accept) do |client|
            process(client)
            client.close
          end
        end
      end

      def stop
        @threads.each(&:kill)
      end

      def process(client)
        r = client.read
        message = JSON.parse(r, symbolize_names: true)
        case message[:type]
        when "spawn"
          spawn_server(message[:directory])
        else
          client.write(
            JSON.generate(
              {
                message: "Unknown message type: #{message[:type]}",
                type: "unknown_message_type"
              }
            )
          )
        end
      end

      def spawn_server
        spawn "cmd /c #{__dir__}/server.bat"
      end

      def server_config
        {
          pid: Process.pid,
          port: @server.addr[1],
          host: @server.addr[3],
          version: RuboCop::Service::VERSION
        }
      end

      class << self
        def connect
          assert_running
          connection =
            TCPSocket.open(server_config[:host], server_config[:port])
          return connection unless block_given?
          yield
          connection.close
        end

        def assert_running
          return if running?

          warn "Service is not running! Please run `rubocop-service start` with administrator privileges."
          exit 1
        end

        def start
          begin
            register unless Win32::Service.exists?(SERVICE_NAME)
            Win32::Service.start SERVICE_NAME
          rescue Errno::EIO
            warn "Could not start service! Missing administrator privileges?"
            exit 1
          end

          puts "Service started successfully!"
        end

        def running?
          return false if server_config[:pid] == -1
          Process.waitpid(server_config[:pid], Process::WNOHANG).nil?
        end

        def server_config_path
          File.expand_path("~/.rubocop-service")
        end

        def server_config
          if File.exist?(server_config_path)
            JSON.load_file(server_config_path, symbolize_names: true)
          else
            DEFAULT_SERVER_CONFIG.dup
          end
        end

        def register
          Win32::Service.create(
            service_name: SERVICE_NAME,
            service_type: Win32::Service::WIN32_OWN_PROCESS,
            description:
              "RuboCop Server for windows, provided by rubocop-service gem",
            start_type: Win32::Service::AUTO_START,
            error_control: Win32::Service::ERROR_NORMAL,
            binary_path_name: "#{RbConfig.ruby} #{File.expand_path(__FILE__)}",
            load_order_group: "Network",
            dependencies: %w[W32Time Schedule]
          )
        end
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  require "win32/daemon"

  class ServiceDaemon < Win32::Daemon
    def service_main
      server = RuboCop::Service::Server.new
      Thread.start { server.start}
      sleep 0.1 while running?
      server.stop
    end

    def service_stop
      exit!
    end
  end

  ServiceDaemon.mainloop
end
