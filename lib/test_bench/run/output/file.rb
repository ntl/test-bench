module TestBench
  class Run
    module Output
      class File
        include Output

        Error = Class.new(RuntimeError)

        def session_output
          @session_output ||= Fixture::Output::Substitute.build
        end
        attr_writer :session_output

        def pended_events
          @pended_events ||= {}
        end
        attr_writer :pended_events

        def only_failure
          @only_failure.nil? ?
            @only_failure = Defaults.only_failure :
            @only_failure
        end
        alias :only_failure? :only_failure
        attr_writer :only_failure

        def configure(writer: nil)
          Fixture::Output.configure(
            self,
            writer:,
            attr_name: :session_output
          )
        end

        handle FileStarted do |file_started|
          process_id = file_started.metadata.process_id

          start(process_id)
        end

        handle FileFinished do |file_finished|
          process_id = file_finished.metadata.process_id
          result = file_finished.result
          file = file_finished.file

          finish(process_id, result, file)
        end

        handle FileTerminated do |file_terminated|
          process_id = file_terminated.metadata.process_id
          file = file_terminated.file

          result = false

          finish(process_id, result, file)
        end

        handle Started do
        end

        handle Finished do
        end

        def finish(process_id, result, file)
          events = pended_events.delete(process_id)

          if only_failure && result
            return
          end

          writer.puts("Running #{file}")

          writer_sequence = writer.sequence

          events ||= []
          events.each do |event_data|
            session_output.receive(event_data)
          end

          if writer.current?(writer_sequence)
            writer.
              style(:faint).
              puts("(Nothing written)")

            writer.puts
          end
        end

        def handle_event_data(event_data)
          pend(event_data)
        end

        def pend_event(event_data)
          process_id = event_data.process_id

          if not started?(process_id)
            start(process_id)
          end

          pended_events = self.pended_events[process_id]
          pended_events << event_data
        end
        alias :pend :pend_event

        def pended_event?(event_data)
          process_id = event_data.process_id

          pended_events = self.pended_events.fetch(process_id) do
            return false
          end

          pended_events.include?(event_data)
        end
        alias :pended? :pended_event?

        def start(process_id)
          if started?(process_id)
            raise Error, "Process already started (Process ID: #{process_id})"
          end

          pended_events[process_id] = []
        end

        def started?(process_id)
          pended_events.key?(process_id)
        end

        module Defaults
          def self.only_failure
            ENV.fetch('TEST_BENCH_ONLY_FAILURE', 'off') == 'on'
          end
        end
      end
    end
  end
end
