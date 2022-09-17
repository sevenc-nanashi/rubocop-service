# frozen_string_literal: true

require "pathname"

module Rubocop
  module Service
    class Installer
      def run
        puts "Finding Rubocop installation..."
        rubocop_path = find_rubocop_path
        unless rubocop_path
          warn "Rubocop not found! Please install it first."
          exit 1
        end
        dputs "rubocop.rb path:", rubocop_path
        rubocop_dir = Pathname.new File.dirname(rubocop_path)
        dputs "rubocop dir:", rubocop_dir
        puts "Rubocop found, patching it..."
        server_root_rb = rubocop_dir / "server.rb"
        server_root_rb.open("a") do |file|
          file.puts "# !!! Patched by rubocop-service !!!"
          file.puts "require 'rubocop/service/patch/server'"
          file.puts "# !!! End of patch !!!"
        end
        dputs "Patched:", server_root_rb
      end

      def find_rubocop_path
        feature_path = $LOAD_PATH.resolve_feature_path("rubocop")
        if feature_path.nil?
          nil
        else
          feature_path[1]
        end
      rescue LoadError => e
        dputs "$LOAD_PATH.resolve_feature_path raised error:", e.message
        nil
      end
    end
  end
end
