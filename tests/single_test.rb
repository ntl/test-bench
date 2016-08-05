require_relative './test_init'

context 'Running a single test by line number' do
  settings = TestBench::Settings::Registry.get binding

  context 'Choose a test by line number' do
    settings.line_number = 13

    test "Will not call this test" do
      refute true
    end

    test "Will call this test" do
      assert true
    end
  end

  context 'Choose a test by number...' do
    settings.line_number = 25
    context '...in a nested context' do
      test "Will not call this test" do
        refute true
      end

      test "Will call this test" do
        assert true
      end
    end
  end
end
