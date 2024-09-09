module TestBench
  class Run
    class GetFiles
      FileError = Class.new(RuntimeError)

      attr_reader :exclude_patterns

      def initialize(exclude_patterns)
        @exclude_patterns = exclude_patterns
      end

      def self.build(exclude: nil)
        exclude_patterns = exclude
        exclude_patterns ||= Defaults.exclude_patterns

        if exclude_patterns.instance_of?(String)
          exclude_patterns = exclude_patterns.split(':')
        end

        new(exclude_patterns)
      end

      def self.call(path, *paths, exclude: nil, &block)
        instance = build(exclude:)
        instance.(path, *paths, &block)
      end

      def self.configure(receiver, exclude: nil, attr_name: nil)
        attr_name ||= :get_files

        instance = build(exclude:)
        receiver.public_send(:"#{attr_name}=", instance)
      end

      def call(path, *paths, &block)
        paths = [path, *paths]

        paths.each do |path|
          if ::File.extname(path).empty?
            pattern = ::File.join(path, '**/*.rb')
          else
            pattern = path
          end

          assure_extant(path)

          Dir.glob(pattern).each do |file|
            excluded = exclude_patterns.any? do |exclude_pattern|
              exclude_pattern = ::File.join('*', exclude_pattern)

              ::File.fnmatch?(exclude_pattern, file, ::File::FNM_EXTGLOB)
            end

            if excluded
              next
            end

            block.(file)
          end
        end
      end

      def assure_extant(path)
        ::File.stat(path)
      rescue Errno::ENOENT => enoent
        raise FileError, enoent.message
      end

      module Defaults
        def self.exclude_patterns
          ENV.fetch('TEST_BENCH_EXCLUDE_FILE_PATTERN', '*_init.rb')
        end
      end
    end
  end
end
