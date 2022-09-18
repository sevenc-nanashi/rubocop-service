# frozen_string_literal: true

module RuboCop
  module Server
    class Cache
      class << self
        def project_dir_cache_key
          @project_dir_cache_key ||= project_dir.tr("/:", "++")
        end

        def write_pid_file
          begin
            pid_path.write(Process.pid)
            yield
          ensure
            dir.rmtree
          end
        rescue Errno::EACCES
          sleep 1
          retry
        end
      end
    end
  end
end
