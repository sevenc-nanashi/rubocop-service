# frozen_string_literal: true

module RuboCop
  module Server
    class Cache
      class << self
        def project_dir
          current_dir = Dir.pwd
          while current_dir != "/" && current_dir.match?(%r{[a-zA-Z]:/})
            # rubocop:disable Style/BlockDelimiters
            if GEMFILE_NAMES.any? { |gemfile|
                 File.exist?(File.join(current_dir, gemfile))
               }
              return current_dir
            end
            # rubocop:enable Style/BlockDelimiters

            current_dir = File.expand_path("..", current_dir)
          end
          Dir.pwd
        end

        def project_dir_cache_key
          @project_dir_cache_key ||= project_dir.tr("/:", "++")
        end

        def write_pid_file
          pid_path.write(Process.pid)
          yield
        ensure
          $unlocker&.call # rubocop:disable Style/GlobalVars
          dir.rmtree
        end

        def acquire_lock
          lock_file = File.open(lock_path, File::CREAT)
          # flock returns 0 if successful, and false if not.
          flock_result = lock_file.flock(File::LOCK_EX | File::LOCK_NB)
          # rubocop:disable Style/GlobalVars
          $unlocker = -> do
            next if lock_file.closed?
            lock_file.flock(File::LOCK_UN)
            lock_file.close
          end
          # rubocop:enable Style/GlobalVars
          yield flock_result != false
        end

        def pid_running?
          Process.kill(0, pid_path.read.to_i) == 1
        rescue Errno::ESRCH, Errno::ENOENT
          false
        end
      end
    end
  end
end
