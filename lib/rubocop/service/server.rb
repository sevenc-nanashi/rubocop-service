# frozen_string_literal: true

# -- NOTE --
# This script may be run separately from the library.

require "socket"
require "json"
require "win32/service"
require "rbconfig"
require_relative "version"
require "open3"
require "securerandom"
require "English"

module RuboCop
  module Service
    class Server
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
        File.write(Server.server_config_path, server_config.to_json)
        puts "Server ready! pid: #{Process.pid}, port: #{port}, host: #{host}"

        loop do
          # process(@server.accept)
          # client.close
          @threads << Thread.start(@server.accept) do |client|
            puts "#{Thread.current.inspect}: Connected #{client.inspect}"
            process(client)
            puts "#{Thread.current.inspect}: Processed #{client.inspect}"
            client.close
          end
        rescue Interrupt
          stop
        end
      end

      def stop
        @threads.each(&:kill)
      end

      def process(connection)
        r = connection.gets
        message = JSON.parse(r, symbolize_names: true)
        case message[:type]
        when "spawn"
          spawn_server(connection, message[:directory])
        else
          connection.puts(
            JSON.generate(
              {
                type: "stderr",
                message:
                  "Unknown message type: #{message[:type]}. This is bug, please report it to https://github.com/sevenc-nanashi/rubocop-service/issues"
              }
            )
          )
          connection.puts(JSON.generate({ type: "exitcode", message: 1 }))
        end
      end

      def spawn_server(connection, directory)
        nonce = SecureRandom.hex(8)
        puts "#{Thread.current.inspect}: Starting server..."
        Open3.popen3(
          {
            "RUBOCOP_SERVICE_SERVER_PROCESS" => "true",
            "RUBOCOP_SERVICE_STARTING_NONCE" => nonce
          },
          "rubocop --start-server",
          chdir: directory
        ) do |i, o, e, t|
          i.close
          queue = Queue.new
          started = false
          con_threads = [
            Thread.start do
              while (od = o.readpartial(4096))
                $stdout.write od
                if od.include?("rubocop-service-nonce:#{nonce}")
                queue << 0
                od.gsub!("rubocop-service-nonce:#{nonce}", "")
                end
                connection.puts(
                  JSON.generate({ type: "stdout", message: od })
                ) unless started
              end
            rescue IOError
              # ignore
            end,
            Thread.start do
              while (data = e.readpartial(4096))
                $stderr.write data
                connection.puts(
                  JSON.generate({ type: "stderr", message: data })
                ) unless started
              end
            rescue IOError
              # ignore
            end,
            Thread.start { queue << t.value },
          ]
          exit_status = queue.pop
          con_threads.each(&:kill)

          connection.puts(
            JSON.generate({ type: "exitcode", message: exit_status })
          )
          puts "#{Thread.current.inspect}: Server started."
          started = true
          t.join
        end
      end

      def server_config
        {
          pid: Process.pid,
          port: port,
          host: host,
          version: RuboCop::Service::VERSION
        }
      end

      def host
        @server.addr[3]
      end

      def port
        @server.addr[1]
      end

      class << self
        def connect
          assert_running
          connection =
            TCPSocket.open(server_config[:host], server_config[:port])
          exitcode = nil
          connection_thread =
            Thread.new do
              while (message = connection.gets)
                data = JSON.parse(message, symbolize_names: true)
                case data[:type]
                when "stdout"
                  $stdout.write(data[:message])
                when "stderr"
                  $stderr.write(data[:message])
                when "exitcode"
                  exitcode = data[:message]
                  break
                end
              end
            rescue IOError
              # ignore
            end
          return connection unless block_given?
          yield connection
          connection_thread.join
          connection.close
          exitcode
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
          begin
            Process.kill(0, server_config[:pid])
            true
          rescue Errno::ESRCH
            false
          end
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
  # require "win32/daemon"

  # class ServiceDaemon < Win32::Daemon
  #   def service_main
  #     server = RuboCop::Service::Server.new
  #     Thread.start { server.start }
  #     sleep 0.1 while running?
  #     server.stop
  #   end

  #   def service_stop
  #     exit!
  #   end
  # end

  # ServiceDaemon.mainloop
  server = RuboCop::Service::Server.new
  server.start
  # sleep 0.1 while running?
  # server.stop
end
