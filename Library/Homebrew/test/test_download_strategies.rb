require 'testing_env'
require 'download_strategy'

class ResourceDouble
  attr_reader :url, :specs

  def initialize(url="http://example.com/foo.tar.gz", specs={})
    @url = url
    @specs = specs
  end
end

class AbstractDownloadStrategyTests < Homebrew::TestCase
  def setup
    @name = "foo"
    @resource = ResourceDouble.new
    @strategy = AbstractDownloadStrategy.new(@name, @resource)
    @args = %w{foo bar baz}
  end

  def test_expand_safe_system_args_with_explicit_quiet_flag
    @args << { :quiet_flag => '--flag' }
    expanded_args = @strategy.expand_safe_system_args(@args)
    assert_equal %w{foo bar baz --flag}, expanded_args
  end

  def test_expand_safe_system_args_with_implicit_quiet_flag
    expanded_args = @strategy.expand_safe_system_args(@args)
    assert_equal %w{foo bar -q baz}, expanded_args
  end

  def test_expand_safe_system_args_does_not_mutate_argument
    result = @strategy.expand_safe_system_args(@args)
    assert_equal %w{foo bar baz}, @args
    refute_same @args, result
  end
end

class VCSDownloadStrategyTests < Homebrew::TestCase
  def setup
    @resource = ResourceDouble.new("http://example.com/bar")
    @strategy = VCSDownloadStrategy
  end

  def escaped(tag)
    "#{ERB::Util.url_encode(@resource.url)}--#{tag}"
  end

  def test_explicit_name
    downloader = @strategy.new("baz", @resource)
    assert_equal "baz--foo", downloader.cache_filename("foo")
  end

  def test_empty_name
    downloader = @strategy.new("", @resource)
    assert_equal escaped("foo"), downloader.cache_filename("foo")
  end

  def test_unknown_name
    downloader = @strategy.new("__UNKNOWN__", @resource)
    assert_equal escaped("foo"), downloader.cache_filename("foo")
  end
end

class DownloadStrategyDetectorTests < Homebrew::TestCase
  def setup
    @d = DownloadStrategyDetector.new
  end

  def test_detect_git_download_startegy
    @d = DownloadStrategyDetector.detect("git://example.com/foo.git")
    assert_equal GitDownloadStrategy, @d
  end

  def test_default_to_curl_strategy
    @d = DownloadStrategyDetector.detect(Object.new)
    assert_equal CurlDownloadStrategy, @d
  end

  def test_raises_when_passed_unrecognized_strategy
    assert_raises(TypeError) do
      DownloadStrategyDetector.detect("foo", Class.new)
    end
  end
end
