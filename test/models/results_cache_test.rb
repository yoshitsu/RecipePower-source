require 'test_helper'

class ResultsCacheTest < ActiveSupport::TestCase
  test "default ResultsCache produces successive integers" do
    rc = ResultsCache.new
    assert_equal (0...10).to_a, rc.items
    10.times { |i|
      refute rc.done?
      assert_equal i, rc.next_item
    }
    assert rc.done?
    assert_equal 10..20, rc.next_range
    5.times { |i|
      refute rc.done?
      assert_equal i+10, rc.next_item
    }
    assert_equal 15..25, rc.next_range
    assert_equal (15...25).to_a, rc.items
    assert_equal "cache", "caches".singularize
    assert_equal "ResultsCache", "ResultsCaches".singularize
    assert rc.save
    rc = ResultsCache.last
    assert_equal 15..25, rc.next_range
    assert_equal (15...25).to_a, rc.items
    assert_equal 15, rc.next_item
  end

  test "It saves and restores parameters" do
    rc = ResultsCache.new params: { id: 10, userid: "name", random: "random" }
    assert_equal 10, rc.param(:id)
    assert_equal "name", rc.param(:userid)
    assert_nil rc.param(:random)

    rc = ListsCache.new params: { id: 10, access: "access" }
    assert_equal 10, rc.param(:id)
    assert_equal "access", rc.param(:access)
  end
end
