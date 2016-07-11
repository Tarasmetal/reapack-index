require File.expand_path '../../helper', __FILE__

TestIndex ||= Class.new MiniTest::Test

class TestIndex::Scan < MiniTest::Test
  include IndexHelper

  def test_ignore_unknown_type
    index = ReaPack::Index.new @dummy_path

    index.scan 'src/main.cpp', String.new
    index.write!

    expected = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<index version="1"/>
    XML

    assert_equal expected, File.read(index.path)
  end

  def test_new_package
    index = ReaPack::Index.new @dummy_path
    index.files = ['Category/Path/Instrument Track.lua']
    index.url_template = 'http://host/$path'

    index.scan index.files.first, <<-IN
      @version 1.0
      @changelog Hello World
    IN

    assert_equal true, index.modified?
    assert_equal '1 new category, 1 new package, 1 new version', index.changelog

    index.write!

    assert_equal false, index.modified?
    assert_empty index.changelog

    expected = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<index version="1">
  <category name="Category/Path">
    <reapack name="Instrument Track.lua" type="script">
      <version name="1.0">
        <changelog><![CDATA[Hello World]]></changelog>
        <source main="true">http://host/Category/Path/Instrument%20Track.lua</source>
      </version>
    </reapack>
  </category>
</index>
    XML

    assert_equal expected, File.read(index.path)
  end

  def test_package_in_root
    index = ReaPack::Index.new @dummy_path
    index.files = ['script.lua', 'Hello/World']
    index.url_template = 'http://host/$path'

    index.scan index.files.first, <<-IN
      @version 1.0
      @provides Hello/World
    IN

    index.write!
    refute_match '<reapack', File.read(index.path)
  end

  def test_edit_version_amend_off
    index = ReaPack::Index.new @real_path
    assert_equal false, index.amend

    index.url_template = 'http://google.com/$path'
    index.files = ['Category Name/Hello World.lua']

    index.scan index.files.first, <<-IN
      @version 1.0
      @changelog New Changelog!
    IN

    assert_equal false, index.modified?
    assert_empty index.changelog
  end

  def test_edit_version_amend_on
    index = ReaPack::Index.new @real_path
    index.commit = @commit
    index.files = ['Category Name/Hello World.lua']
    index.time = Time.now # must not be added to the index in amend mode
    index.url_template = 'http://google.com/$path'

    index.amend = true
    assert_equal true, index.amend

    index.scan index.files.first, <<-IN
      @version 1.0
      @changelog Intermediate Changelog!
    IN

    # when reindexing the same file a second time,
    # the changelog is expected to only have been bumped a single time
    index.scan index.files.first, <<-IN
      @version 1.0
      @changelog New Changelog!
    IN

    assert index.modified?, 'index is not modified'
    assert_equal '1 modified package, 1 modified version', index.changelog

    index.write @dummy_path
    contents = File.read @dummy_path

    assert_match @commit, contents
    assert_match 'New Changelog!', contents
    assert_match '2015', contents
  end

  def test_edit_version_amend_unmodified
    index = ReaPack::Index.new @real_path
    index.amend = true

    index.url_template = 'https://google.com/$path'
    index.files = ['Category Name/Hello World.lua']

    index.scan index.files.first, <<-IN
      @version 1.0
      @author cfillion
      @changelog Fixed a division by zero error.
    IN

    assert_equal false, index.modified?
    assert_empty index.changelog
  end

  def test_author
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua']

    index.scan index.files.first, <<-IN
      @version 1.0
      @author cfillion
    IN

    index.write!
    assert_match '<version name="1.0" author="cfillion">', File.read(index.path)
  end

  def test_noindex
    index = ReaPack::Index.new @real_path

    index.scan 'script.lua', '@noindex'

    assert_equal false, index.modified?
  end

  def test_noindex_autoremove
    index = ReaPack::Index.new @real_path
    index.commit = @commit

    index.scan 'Category Name/Hello World.lua', '@noindex'

    assert_equal true, index.modified?
    assert_equal '1 removed package', index.changelog

    index.write @dummy_path
    contents = File.read @dummy_path

    assert_match @commit, contents
    refute_match '<category', contents
  end

  def test_metapackage_on
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua']

    error = assert_raises ReaPack::Index::Error do
      index.scan index.files.first, "@version 1.0\n@metapackage"
    end

    assert_equal 'no files provided', error.message
  end

  def test_metapackage_off
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/extension.ext']

    index.scan index.files.first, "@version 1.0\n@metapackage false"
  end

  def test_version_time
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua']
    index.time = Time.new 2016, 2, 11, 20, 16, 40, -5 * 3600

    index.scan index.files.first, '@version 1.0'

    index.write!
    assert_match '<version name="1.0" time="2016-02-12T01:16:40Z">',
      File.read(index.path)
  end

  def test_description
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua']

    index.scan index.files.first, <<-IN
      @version 1.0
      @description From the New World
    IN

    index.write!
    assert_match 'desc="From the New World"', File.read(index.path)
  end

  def test_description_alias
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua']

    index.scan index.files.first, <<-IN
      @version 1.0
      @reascript_name Right
      @description Wrong
    IN

    index.write!
    assert_match 'desc="Right"', File.read(index.path)
  end

  def test_documentation
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Category/script.lua', 'Category/effect.jsfx']

    index.scan index.files.first, <<-IN
      @version 1.0
      @documentation
        # Hello World
    IN

    index.scan index.files.last, <<-IN
      @version 1.0
      @instructions
        # Chunky Bacon
    IN

    index.write!
    contents = File.read index.path
    assert_match 'Hello World\\par}', contents
    assert_match 'Chunky Bacon\\par}', contents
  end

  def test_extension
    index = ReaPack::Index.new @dummy_path
    index.files = ['Extensions/reapack.ext']

    index.scan index.files.first, <<-IN
      @version 1.0
      @provides
        reaper_reapack.so http://example.com/$path
    IN

    expected = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<index version="1">
  <category name="Extensions">
    <reapack name="reapack.ext" type="extension">
      <version name="1.0">
        <source file="reaper_reapack.so">http://example.com/reaper_reapack.so</source>
      </version>
    </reapack>
  </category>
</index>
    XML

    index.write!
    assert_equal expected, File.read(index.path)
  end

  def test_effect
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Dynamics/super_compressor.jsfx']

    index.scan index.files.first, '@version 1.0'

    expected = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<index version="1">
  <category name="Dynamics">
    <reapack name="super_compressor.jsfx" type="effect">
      <version name="1.0">
        <source main="true">http://host/Dynamics/super_compressor.jsfx</source>
      </version>
    </reapack>
  </category>
</index>
    XML

    index.write!
    assert_equal expected, File.read(index.path)
  end

  def test_data
    index = ReaPack::Index.new @dummy_path
    index.url_template = 'http://host/$path'
    index.files = ['Grooves/sws.data', 'Grooves/sws/test.mid']

    index.scan index.files.first, "@version 1.0\n@provides sws/*.mid"

    expected = <<-XML
<?xml version="1.0" encoding="utf-8"?>
<index version="1">
  <category name="Grooves">
    <reapack name="sws.data" type="data">
      <version name="1.0">
        <source file="sws/test.mid">http://host/Grooves/sws/test.mid</source>
      </version>
    </reapack>
  </category>
</index>
    XML

    index.write!
    assert_equal expected, File.read(index.path)
  end
end
