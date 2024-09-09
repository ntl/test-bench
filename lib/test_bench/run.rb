module TestBench
  class Run
    Error = Class.new(RuntimeError)

    include Events

    def telemetry
      @telemetry ||= Telemetry::Substitute.build
    end
    attr_writer :telemetry

    def session
      @session ||= Session::Substitute.build
    end
    attr_writer :session

    def get_files
      @get_files ||= GetFiles::Substitute.build
    end
    attr_writer :get_files

    def executor
      @executor ||= Executor::Substitute.build
    end
    attr_writer :executor

    def random_generator
      @random_generator ||= Pseudorandom::Generator.build
    end
    attr_writer :random_generator

    def path_sequence
      @path_sequence ||= 0
    end
    attr_writer :path_sequence

    def self.build(exclude: nil, session: nil)
      instance = new

      GetFiles.configure(instance, exclude:)

      Executor::Serial.configure(instance)

      Pseudorandom::Generator.configure(instance)

      if session.nil?
        session = Session.build do |telemetry|
          Output::File.register(telemetry)
          Output::Summary::Error.register(telemetry)
          Output::Summary.register(telemetry)
        end
      end

      instance.telemetry = session.telemetry

      Session.configure(instance, session:)

      instance
    end

    def self.call(path, session_store: nil, exclude: nil)
      session_store ||= Session::Store.instance

      instance = build(exclude:)

      session_store.reset(instance.session)

      instance.(path)
    end

    def self.configure(receiver, exclude: nil, session: nil, attr_name: nil)
      attr_name ||= :run

      instance = build(exclude:, session:)
      receiver.public_send(:"#{attr_name}=", instance)
    end

    def call(path)
      run do
        path(path)
      end
    end

    def run(&block)
      if ran?
        raise Error, "Already ran"
      end

      telemetry.record(Started.build(random_generator.seed))

      executor.start

      if not block.nil?
        block.(self)

        if not ran?
          raise Error, "No files were ran"
        end
      end

      executor.finish

      if session.passed?
        result = true
      elsif session.failed?
        result = false
      end

      telemetry.record(Finished.build(random_generator.seed, result))
      result
    end
    alias :! :run

    def path(path)
      self.path_sequence += 1

      get_files.(path) do |file|
        executor.execute(file)
      end

    rescue GetFiles::FileError
      warn "#{path}: No such file or directory"

      session.record_failure
    end
    alias :<< :path

    def ran?
      path_sequence > 0
    end

    module Substitute
      def self.build
        Run.build
      end

      class Run < Run
        def self.build
          new
        end

        def path?(path)
          get_files.path?(path)
        end

        def set_result(result)
          if result
            session.record_assertion
          else
            session.record_failure
          end
        end
      end
    end
  end
end
