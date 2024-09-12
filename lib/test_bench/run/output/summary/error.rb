module TestBench
  class Run
    module Output
      class Summary
        class Error
          include Output

          StateError = Class.new(RuntimeError)

          Failed = Fixture::Events::Failed

          attr_accessor :current_file

          def failure_summary
            @failure_summary ||= {}
          end
          attr_writer :failure_summary

          handle FileStarted do |file_started|
            file = file_started.file

            start_file(file)
          end

          handle Failed do
            current_file.record_failure
          end

          handle FileFinished do |file_finished|
            file = file_finished.file
            result = file_finished.result

            finish_file(file, result)
          end

          handle FileTerminated do |file_terminated|
            file = file_terminated.file

            error_message = file_terminated.error_message

            finish_file(file, error_message:)
          end

          handle Finished do |finished|
            if not failure_summary.empty?
              print_summary
            end
          end

          def print_summary
            writer.style(:bold, :underline, :red).puts("Failure Summary:")

            failure_summary.each_value do |file_record|
              file, failures, error_message = file_record.to_a

              writer
                .style(:faint, :red)
                .print("-")
                .style(:reset_intensity, :bold)
                .print(" #{file}")
                .style(:reset_intensity)
                .print(":")

              if failures > 0
                writer.print(" %i failure%s" % [
                  failures,
                  failures == 1 ? '' : 's'
                ])

                if not error_message.nil?
                  writer.print(".")
                end
              end

              if not error_message.nil?
                writer.puts(" File terminated, error:")

                writer.style(:red).puts("  #{error_message}")
              else
                writer.puts
              end

              writer.puts
            end
          end

          def start_file(file)
            if not current_file.nil?
              raise StateError, "Already started file #{current_file.file.inspect} (File: #{file.inspect})"
            end

            file = File.build(file)

            self.current_file = file
          end

          def finish_file(file, result=nil, error_message: nil)
            result ||= false

            if not current_file?(file)
              raise StateError, "Cannot finish file #{file.inspect} (Current File: #{current_file&.file.inspect})"
            end

            if not result
              if not error_message.nil?
                current_file.error_message = error_message
              end

              failure_summary[file] = current_file
            end

            self.current_file = nil
          end

          def current_file?(file=nil)
            return false if current_file.nil?

            if not file.nil?
              file == current_file.file
            else
              true
            end
          end

          File = Struct.new(:file, :failures, :error_message) do
            def self.build(file)
              failures = 0

              new(file, failures)
            end

            def record_failure
              self.failures += 1
            end
          end
        end
      end
    end
  end
end
