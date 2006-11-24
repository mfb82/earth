require File.dirname(__FILE__) + '/../test_helper'

class FileInfoTest < Test::Unit::TestCase
  fixtures :file_info

  def test_stat
    # Getting a File::Stat from a "random" file
    stat = File.lstat(File.dirname(__FILE__) + '/../test_helper.rb')
    file_info(:first).stat = stat
    # Testing equality in the long winded way
    assert_equal(stat.mtime, file_info(:first).modified)
    assert_equal(stat.size, file_info(:first).size)
    assert_equal(stat.uid, file_info(:first).uid)
    assert_equal(stat.gid, file_info(:first).gid)
    # And we should be able to read back as a stat object
    s = file_info(:first).stat
    assert_equal(stat.mtime, s.mtime)
    assert_equal(stat.size, s.size)
    assert_equal(stat.uid, s.uid)
    assert_equal(stat.gid, s.gid)
    # And we should be able to directly compare the stats even though they are different kinds of object
    assert_kind_of(File::Stat, stat)
    assert_kind_of(FileInfo::Stat, s)
    assert_equal(stat, s)
    assert_equal(s, stat)
  end
end
