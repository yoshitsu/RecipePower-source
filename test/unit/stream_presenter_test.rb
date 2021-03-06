require 'test_helper'
class StreamPresenterTest < ActiveSupport::TestCase
  fixtures :sites
  fixtures :users

  def setup
    @user = users(:thing1)
  end

  test "ten items stream with single offset" do
    sessionid = "wklejrkjovekj23kjkj3f"
    superklass = ResultsCache
    sp = StreamPresenter.new sessionid, "", IntegersCache, @user.id, false, stream: "12"
    assert_equal (12..21).to_a, sp.items
  end

  test "three items stream according to offset" do
    sessionid = "wklejrkjovekj23kjkj3f"
    superklass = ResultsCache
    sp = StreamPresenter.new sessionid, "", IntegersCache, @user.id, false, controller: "integers", action: "index", stream: "8-11"
    refute_nil sp.next_range
    assert_equal (8...11).to_a, sp.items
    assert_equal 8, sp.next_item
    assert_equal 9, sp.next_item
    assert_equal 10, sp.next_item
    assert_nil sp.next_item
    assert 11...14, sp.next_range
  end

  test "presenter gets appropriate ResultsCache" do
    sessionid = "wklejrkjovekj23kjkj3f"
    superklass = ResultsCache
    sp = StreamPresenter.new sessionid, "", IntegersCache, @user.id, false, controller: "integer", action: "index"
    assert_equal IntegersCache, sp.results.class
  end

  test "presenter responds correctly for dumping" do
    sessionid = "wklejrkjovekj23kjkj3f"
    superklass = ResultsCache
    sp = StreamPresenter.new sessionid, "", IntegersCache, @user.id, false
    refute sp.stream?
    refute sp.dump?
  end

  test "presenter parses existing tag" do
    sessionid = "wklejrkjovekj23kjkj3f"
    t = tags(:jal)
  end
end