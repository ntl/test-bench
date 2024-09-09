module TestBench
  class Run
    module Output
      class Summary
        include Output

        StateError = Class.new(RuntimeError)

        def writer
          @writer ||= Fixture::Writer::Substitute.build
        end
        attr_writer :writer

        def tests_finished
          @tests_finished ||= 0
        end
        attr_writer :tests_finished

        def tests_passed
          @tests_passed ||= 0
        end
        attr_writer :tests_passed

        def tests_failed
          @tests_failed ||= 0
        end
        attr_writer :tests_failed

        def tests_skipped
          @tests_skipped ||= 0
        end
        attr_writer :tests_skipped

        def contexts_skipped
          @contexts_skipped ||= 0
        end
        attr_writer :contexts_skipped

        def files_finished
          @files_finished ||= 0
        end
        attr_writer :files_finished

        def files_terminated
          @files_terminated ||= 0
        end
        attr_writer :files_terminated

        attr_accessor :start_time
        attr_accessor :finish_time
        attr_accessor :elapsed_time

        handle TestFinished do |test_finished|
          self.tests_finished += 1

          if test_finished.result
            self.tests_passed += 1
          else
            self.tests_failed += 1
          end
        end

        handle TestSkipped do
          self.tests_skipped += 1
        end

        handle ContextSkipped do
          self.contexts_skipped += 1
        end

        handle FileFinished do
          self.files_finished += 1
        end

        handle FileTerminated do
          self.files_terminated += 1
        end

        handle Started do |started|
          start_time = started.metadata.time

          self.start_time = start_time
        end

        handle Finished do |finished|
          finish_time = finished.metadata.time

          record_finish_time(finish_time)

          finish
        end

        def record_finish_time(finish_time)
          if start_time.nil?
            raise StateError, "Start time isn't set"
          end

          self.finish_time = finish_time

          elapsed_time = finish_time - start_time
          self.elapsed_time = elapsed_time
        end

        def finish
          writer.print("Finished running %i file%s, " % [
            files_finished,
            files_finished == 1 ? '' : 's'
          ])

          if files_terminated > 0
            writer
              .style(:bold, :red)
              .puts("%i file%s terminated" % [
                files_terminated,
                files_terminated == 1 ? '' : 's'
              ])
          else
            writer.puts("0 files terminated")
          end

          writer.print("Ran %i test%s" % [
            tests_finished,
            tests_finished == 1 ? '' : 's'
          ])

          if not elapsed_time.nil?
            tests_per_second = tests_finished / elapsed_time
            writer.print(" in %0.3fs (%i test%s/second)" % [
              elapsed_time,
              tests_per_second,
              tests_finished == 1 ? '' : 's'
            ])
          end
          writer.puts

          skip_count = tests_skipped + contexts_skipped

          if tests_passed > 0
            if skip_count.zero? && tests_failed.zero?
              writer.style(:bold)
            end

            writer
              .style(:green)
              .print("#{tests_passed} passed")
              .style(:reset_fg)

            if skip_count.zero? && tests_failed.zero?
              writer.style(:reset_intensity)
            end
          else
            writer
              .style(:bold, :faint, :italic)
              .print("0 passed")
              .style(:reset_italic, :reset_intensity)
          end
          writer.print(", ")

          if skip_count.zero?
            writer.print("0 skipped")
          else
            writer
              .style(:bold, :yellow)
              .print("%i%s skipped" % [
                skip_count,
                contexts_skipped > 0 ? '+' : ''
              ])
              .style(:reset_fg, :reset_intensity)
          end
          writer.print(", ")

          if tests_failed > 0
            writer
              .style(:bold, :red)
              .puts("#{tests_failed} failed")
          else
            writer.puts("0 failed")
          end

          writer.puts
        end
      end
    end
  end
end
