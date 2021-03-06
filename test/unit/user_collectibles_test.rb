require 'test_helper'
class UserCollectiblesTest < ActiveSupport::TestCase
  fixtures :users
  fixtures :recipes
  fixtures :feeds
  # fixtures :feed_entries
  # fixtures :lists
  # fixtures :products
  fixtures :sites
  test "Collectibles access methods defined" do
    user = users(:thing1)
    # feed_entry = feed_entries(:fe1)
    # list = lists(:list1)
    # product = products(:prod1)

    rcp = recipes(:rcp)
    assert user.recipes.empty?
    user.recipes<<rcp
    assert_equal 1, user.recipes.size
    refute user.recipes.empty?
    user.uncollect rcp
    user.reload
    assert user.recipes.empty?

    site = sites(:nyt)
    assert user.sites.empty?
    user.sites<<site
    assert_equal 1, user.sites.size
    refute user.sites.empty?
    user.uncollect site
    user.reload
    assert user.sites.empty?

    feed = feeds(:feed1)
    assert user.feeds.empty?
    user.feeds<<feed
    assert_equal 1, user.feeds.size
    refute user.feeds.empty?
    user.uncollect feed
    user.reload
    assert user.feeds.empty?

    collected_user = users(:thing2)
    assert user.users.empty?
    user.users<<collected_user
    assert_equal 1, user.users.size
    refute user.users.empty?
    user.uncollect collected_user
    user.reload
    assert user.users.empty?

  end

  test "User-side collection" do
    user = users(:thing1)
    rcp = recipes(:rcp)
    assert user.recipes.empty?
    user.touch rcp
    # Touching the recipe shouldn't mean it's in the collection
    assert user.collection_pointers.empty?
    assert user.recipes.empty?
    refute user.touched_pointers.empty?
    refute user.touched_pointers.first.in_collection
    assert rcp.users.empty?

    user.collect rcp
    user.reload
    # ...though it will be among the collection_pointers and the recipes
    assert_equal 1, user.collection_pointers.size
    assert_equal 1, user.touched_pointers.size
    assert_equal rcp, user.recipes.first
    assert_equal 1, rcp.users.size
    assert_equal 1, user.recipes.size

    user.collect rcp  # Can only collect it once
    user.reload
    assert_equal 1, user.collection_pointers.size
    assert_equal 1, user.touched_pointers.size
    assert_equal rcp, user.recipes.first
    assert_equal 1, user.recipes.size
    assert_equal 1, rcp.users.size

    # Uncollecting it still leaves it touched
    user.uncollect rcp
    assert user.collection_pointers.empty?
    assert user.recipes.empty?
    assert_equal 1, user.touched_pointers.size
    assert_equal 1, user.touched_recipes.size
    assert rcp.users.empty?
  end
end