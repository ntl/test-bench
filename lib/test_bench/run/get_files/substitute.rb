module TestBench
  class Run
    class GetFiles
      module Substitute
        def self.build
          GetFiles.new
        end

        class GetFiles
          attr_accessor :file_error
          def file_error? = !!file_error

          def files
            @files ||= []
          end
          attr_writer :files
          alias :set_files :files=

          def paths
            @paths ||= []
          end

          def file_error!
            self.file_error = true
          end

          def call(path, *paths, &block)
            [path, *paths].each do |path|
              self.paths << path
            end

            if file_error?
              raise FileError
            end

            files.each(&block)
          end

          def path?(path)
            paths.include?(path)
          end
        end
      end
    end
  end
end
