require_relative './test_init'

context "Settings" do
  context "Abort on error" do
    test do
      settings = TestBench::Settings.new

      settings.abort_on_error = true

      assert settings.abort_on_error == true
    end

    test "Default is not activated" do
      settings = TestBench::Settings.new

      assert settings.abort_on_error == false
    end
  end

  context "Color" do
    test do
      settings = TestBench::Settings.new

      settings.color = false

      assert settings.color == false
    end

    test "Default is nil (autodetect)" do
      settings = TestBench::Settings.new

      assert settings.color == nil
    end
  end

  context "Reverse backtraces" do
    test do
      settings = TestBench::Settings.new

      settings.reverse_backtraces = true

      assert settings.reverse_backtraces == true
    end

    test "Default is false" do
      settings = TestBench::Settings.new

      assert settings.reverse_backtraces == false
    end
  end

  context "Exclude pattern" do
    test do
      settings = TestBench::Settings.new

      settings.exclude_pattern = 'some-pattern'

      assert settings.exclude_pattern == 'some-pattern'
    end

    test "Default is files ending with \"_init.rb\"" do
      settings = TestBench::Settings.new

      assert settings.exclude_pattern == "_init\\.rb$"
    end
  end

  context "Adjusting verbosity" do
    test "Raising" do
      settings = TestBench::Settings.new

      settings.raise_verbosity

      assert settings.writer.level == :verbose
    end

    test "Lowering" do
      settings = TestBench::Settings.new

      settings.lower_verbosity

      assert settings.writer.level == :quiet
    end
  end

  context "Recording telemetry" do
    test do
      settings = TestBench::Settings.new

      settings.record_telemetry = true

      assert settings.record_telemetry == true
    end

    test "Default is not activated" do
      settings = TestBench::Settings.new

      assert settings.record_telemetry == false
    end
  end

  context "Line number" do
    test do
      settings = TestBench::Settings.new

      settings.line_number = 10

      assert settings.line_number == 10
    end

    test "Will convert a string" do
      settings = TestBench::Settings.new

      settings.line_number = "10"

      assert settings.line_number == 10
    end

    test "Will be nil on an invalid string" do
      settings = TestBench::Settings.new

      settings.line_number = "bad value"

      assert settings.line_number.nil?
    end

    test "Will be nil on a negative number" do
      settings = TestBench::Settings.new

      settings.line_number = -10

      assert settings.line_number.nil?
    end

    test "Default is nil" do
      settings = TestBench::Settings.new

      assert settings.line_number.nil?
    end
  end
end
