module TestBench
  class Run
    module Executor
      class Serial
        include Executor

        def run_file
          @run_file ||= Run::File.build
        end
        attr_writer :run_file

        def session_store
          @session_store ||= Fixture::Session::Store.new
        end
        attr_writer :session_store

        def configure
          Fixture::Session::Store.configure(self)
        end

        def execute(file)
          run_file.(file)

        rescue => exception
          session = session_store.fetch

          session.record_failure

          STDERR.write("#{exception.full_message}\n")
        end
      end
    end
  end
end
