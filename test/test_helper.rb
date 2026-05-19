require File.expand_path('../../../test/test_helper', __dir__)

# Ensure Redmine's test fixtures are in the fixture_paths (Rails 6/7 compatibility)
ActiveSupport::TestCase.fixture_paths = [File.expand_path("../../../test/fixtures", __dir__)]
