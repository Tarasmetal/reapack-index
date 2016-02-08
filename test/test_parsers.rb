class TestParsers < MiniTest::Test
  def test_wordpress
    mh = MetaHeader.new <<-IN
/**
 * Version: 1.1
 */

/**
 * Changelog:
 * v1.2 (2010-01-01)
\t+ Line 1
\t+ Line 2
 * v1.1 (2011-01-01)
\t+ Line 3
\t+ Line 4
 * v1.0 (2012-01-01)
\t+ Line 5
\t+ Line 6
 */

 Test
    IN

    changelog = <<-LOG
(2011-01-01)
+ Line 3
+ Line 4
    LOG

    assert_equal '1.1', mh[:version]
    assert_equal changelog.chomp, mh[:changelog]
  end
end
