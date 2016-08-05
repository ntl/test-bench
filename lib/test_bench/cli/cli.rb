module TestBench
  class CLI
    attr_reader :argv
    attr_writer :settings

    def initialize argv
      @argv = argv
    end

    def self.call argv=nil
      argv ||= ARGV

      instance = new argv
      instance.settings = Settings.toplevel
      instance.()
    end

    def call
      option_parser.parse! argv

      paths = argv
      paths << 'tests' if paths.empty?
      if paths.length == 1
        path, line_number = paths[0].split(':')
        settings.line_number = line_number
        paths = [path]
      end

      current_directory = File.expand_path Dir.pwd

      TestBench.activate

      TestBench::Runner.(paths, current_directory) or exit 1
    end

    def help
      puts option_parser.help
      puts
      puts <<-TEXT
If no paths are specified, #{program_name} runs all files in ./tests. The following environment variables can also control execution:

        TEST_BENCH_COLOR               Set color on or off
        TEST_BENCH_ABORT_ON_ERROR      Same as -a or --abort-on-error
        TEST_BENCH_RECORD_TELEMETRY    Causes Test Bench to preserve telemetry events (needed for testing Test Bench itself)
        TEST_BENCH_REVERSE_BACKTRACES  Prints exceptions in reverse order
        TEST_BENCH_QUIET               Same as -q or --quiet
        TEST_BENCH_VERBOSE             Same as -v or --verbose

      TEXT
    end

    def option_parser
      @option_parser ||= OptionParser.new do |parser|
        parser.on '-a', '--abort-on-error', "Exit immediately after any test script fails" do
          settings.abort_on_error = true
        end

        parser.on '-h', '--help', "Print this help message and exit successfully" do
          help
          exit 0
        end

        parser.on '-q', '--quiet', "Lower verbosity level" do
          settings.lower_verbosity
        end

        parser.on '-r', '--reverse-backtraces', "Reverse error backtraces" do
          settings.reverse_backtraces = true
        end

        parser.on '-v', '--verbose', "Raise verbosity level" do
          settings.raise_verbosity
        end

        parser.on '-V', '--version', "Print version and exit successfully" do
          puts "test-bench (#{parser.program_name}) version #{version}"
          exit 0
        end

        parser.on '-x', '--exclude PATTERN', %{Filter out files matching PATTERN (Default is "_init$")} do |pattern|
          settings.exclude_pattern = pattern
        end
      end
    end

    def program_name
      File.basename $PROGRAM_NAME
    end

    def settings
      @settings ||= Settings.new
    end

    def version
      spec = Gem.loaded_specs['test_bench']

      if spec
        spec.version
      else
        '(local)'.freeze
      end
    end
  end
end
