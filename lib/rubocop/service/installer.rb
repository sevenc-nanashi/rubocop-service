# frozen_string_literal: true

require "pathname"

module RuboCop
  module Service
    class Installer
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
        # if (rubocop_dir / ".rubocop-service_patched").exist?
        #   warn "Already patched! Use `rubocop-service uninstall` to restore."
        #   exit 1
        # end
        puts "RuboCop found, patching it..."
        Dir
          .glob("#{__dir__}/patch/**/*.rb")
          .each do |libpath|
            path =
              (Pathname.new libpath).relative_path_from(__dir__).sub(
                "patch/",
                ""
              )
            rubocop_file = rubocop_dir / "rubocop" / path
            rubocop_file.open("a") do |file|
              file.puts "# !!! Patched by rubocop-service !!!"
              file.puts "require 'rubocop/service/patch/#{path}' if RuboCop::Platform.windows?"
              file.puts "# !!! End of patch !!!"
            end
            dputs "Patched:", rubocop_file
          end
        (rubocop_dir / ".rubocop-service_patched").open("w").close
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
