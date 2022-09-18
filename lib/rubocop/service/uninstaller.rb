# frozen_string_literal: true

require "pathname"

module RuboCop
  module Service
    class Uninstaller
      def run
        puts "Finding RuboCop installation..."
        rubocop_path = find_rubocop_path
        unless rubocop_path
          warn "RuboCop not found! Please install it first."
          exit 1
        end
        dputs "rubocop.rb path:", rubocop_path
        rubocop_dir = Pathname.new File.dirname(rubocop_path)
        dputs "rubocop dir:", rubocop_dir
        unless (rubocop_dir / ".rubocop-service_patched").exist?
          warn "Not patched! Use `rubocop-service install` to install."
          exit 1
        end
        puts "RuboCop found, unpatching it..."
        rubocop_files = rubocop_dir.glob("rubocop/**/*.rb")
        rubocop_files.filter! do |path|
          dputs "Checking:", path
          content = path.read
          if content.gsub!(
               /# !!! Patched by rubocop-service !!!.*# !!! End of patch !!!\n/m,
               ""
             )
            dputs "Unpatched."
            path.write content
          else
            dputs "Not patched."
            false
          end
        end
        (rubocop_dir / ".rubocop-service_patched").delete
        puts "Unpatched #{rubocop_files.size} files! Run `rubocop-service install` to install again."
      end

      def find_rubocop_path
        feature_path = $LOAD_PATH.resolve_feature_path("rubocop")
        feature_path.nil? ? nil : feature_path[1]
      rescue LoadError => e
        dputs "$LOAD_PATH.resolve_feature_path raised error:", e.message
        nil
      end
    end
  end
end
