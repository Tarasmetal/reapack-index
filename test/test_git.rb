require File.expand_path '../helper', __FILE__

class TestGit < MiniTest::Test
  include GitHelper

  def setup
    @path, @repo = init_git
  end

  def teardown
    FileUtils.rm_r @path
  end

  def test_path
    realpath = Pathname.new(@path).realpath
    assert_equal realpath.to_s, @git.path
  end

  def test_relative_path
    assert_equal 'test', @git.relative_path(File.join(@git.path, 'test'))
  end

  def test_guess_url_template
    assert_nil @git.guess_url_template

    @repo.remotes.create 'origin', 'git@github.com:User/Repo.git'
    assert_match "https://github.com/User/Repo/raw/$commit/$path",
      @git.guess_url_template

    @repo.remotes.set_url 'origin', 'https://github.com/User/Repo.git'
    assert_match "https://github.com/User/Repo/raw/$commit/$path",
      @git.guess_url_template

    @repo.remotes.set_url 'origin', 'https://github.com/User/Repo'
    assert_match "https://github.com/User/Repo/raw/$commit/$path",
      @git.guess_url_template

    @repo.remotes.set_url 'origin', 'scp://weird/url'
    assert_nil @git.guess_url_template
  end

  def test_create_initial_commit
    index = @repo.index
    index.add @git.relative_path(mkfile('ignored_staged'))
    index.write

    mkfile 'ignored'

    assert_equal true, @git.empty?
    commit = @git.create_commit 'initial commit', [mkfile('file')]
    assert_equal false, @git.empty?

    assert_equal commit, @git.last_commit
    assert_equal 'initial commit', commit.message
    assert_equal ['file'], commit.each_diff.map {|d| d.file }
    assert_equal ['file'], commit.filelist
  end

  def test_create_subsequent_commit
    initial = @git.create_commit 'initial commit', [mkfile('file1')]

    mkfile 'ignored'

    index = @repo.index
    index.add @git.relative_path(mkfile('ignored_staged'))
    index.write

    commit = @git.create_commit 'second commit', [mkfile('file2')]
    refute_equal initial, commit
    assert_equal 'second commit', commit.message
    assert_equal ['file2'], commit.each_diff.map {|d| d.file }
    assert_equal ['file1', 'file2'], commit.filelist
  end

  def test_commit_info
    commit = @git.create_commit "initial commit\ndescription", [mkfile('file')]
    assert_equal "initial commit\ndescription", commit.message
    assert_equal 'initial commit', commit.summary

    assert commit.id.start_with?(commit.short_id)
    assert_equal 7, commit.short_id.size

    assert_kind_of Time, commit.time
    assert_equal ['file'], commit.filelist
  end

  def test_diff
    hash = proc {|c|
      c.each_diff.map {|d| [d.status, d.file, d.new_content] }
    }

    c1 = @git.create_commit 'initial commit', [mkfile('file1', 'initial')]
    assert_equal [[:added, 'file1', 'initial']], hash[c1]

    c2 = @git.create_commit 'second commit',
      [mkfile('file1', 'second'), mkfile('file2')]
    assert_equal [[:modified, 'file1', 'second'], [:added, 'file2', '']], hash[c2]

    file1 = File.join @git.path, 'file1'
    File.delete file1
    c3 = @git.create_commit 'second commit', [file1]
    assert_equal [[:deleted, 'file1', nil]], hash[c3]
  end

  def test_commits_since
    assert_equal [], @git.commits_since(nil)
    assert_equal [], @git.commits
    c1 = @git.create_commit 'first', []

    assert_equal [c1], @git.commits_since(nil)
    assert_equal [], @git.commits_since(c1.id)

    c2 = @git.create_commit 'second', []
    assert_equal [c1, c2], @git.commits_since(nil)
    assert_equal [c1, c2], @git.commits
    assert_equal [c2], @git.commits_since(c1.id)

    INVALID_HASHES.each {|hash|
      assert_equal [c1, c2], @git.commits_since(hash)
    }
  end

  def test_get_commit
    c = @git.create_commit 'first', []
    assert_equal c, @git.get_commit(c.id)

    INVALID_HASHES.each {|hash|
      assert_nil @git.get_commit(hash)
    }
  end

  def test_multibyte_filename
    filename = "\342\200\224.lua"

    @git.create_commit 'initial commit', [mkfile(filename)]
    assert_equal filename, @git.last_commit.each_diff.first.file
  end

  def test_invalid_char_sequence
    content = "\x97"
    @git.create_commit 'initial commit', [mkfile('test.lua', content)]

    assert_equal content, @git.last_commit.each_diff.first.new_content
  end

  def test_path_encoding
    path = mkpath 'еуые'
    Dir.mkdir path
    path.encode! Encoding::Windows_1251
    path.freeze

    git = ReaPack::Index::Git.new path # should not throw
    assert_equal @git.path, git.path
  end
end
