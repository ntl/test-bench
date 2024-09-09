module TestBench
  class Run
    class File
      ReadFileError = Class.new(RuntimeError)

      def root_directory
        @root_directory ||= ::Dir.pwd
      end
      attr_writer :root_directory

      def session
        @session ||= Fixture::Session::Substitute.build
      end
      attr_writer :session

      def random_generator
        @random_generator ||= Pseudorandom::Generator.build
      end
      attr_writer :random_generator

      def self.build(session: nil)
        instance = new
        Fixture::Session.configure(instance, session:)
        Pseudorandom::Generator.configure(instance)
        instance
      end

      def call(file)
        random_generator.reset(file)

        begin
          source = ::File.read(file)
        rescue SystemCallError => error
          raise ReadFileError, "Couldn't run #{file}: #{error.message.partition(' @ ').first}"
        end

        failure_sequence = session.failure_sequence

        session.record_event(Events::FileStarted.new(file))

        begin
          TOPLEVEL_BINDING.eval(source, file)

        rescue => exception
          raise exception

        ensure
          if not exception.nil?
            error_message = error_message(exception)
            error_text = error_text(exception)

            session.record_event(Events::FileTerminated.new(file, error_message, error_text))

            raise exception
          end
        end

        failed = session.failed?(failure_sequence)
        result = !failed

        session.record_event(Events::FileFinished.new(file, result))

        result
      end

      def error_message(exception)
        error_message = exception.full_message(order: :top, highlight: false).each_line(chomp: true).first

        if error_message.delete_prefix!(root_directory)
          error_message.delete_prefix!('/')
        end

        error_message
      end

      def error_text(exception)
        exception.full_message
      end
    end
  end
end
