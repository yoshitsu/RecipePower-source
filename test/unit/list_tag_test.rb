# require 'test/unit'
require 'test_helper'

# Tests of tag support in lists
class ListTagTest < ActiveSupport::TestCase

  def setup
    @owner = users(:thing3)
    @lst_name = "Test List"
    @lst = List.assert @lst_name, @owner, create: true
    # Get a recipe under a tag
    @lst.store (@included = FactoryGirl.create(:recipe))

    @tagged = FactoryGirl.create(:recipe)
    @tag = Tag.assert("Test Tag", userid: @owner.id)
    TaggingServices.new(@tagged).tag_with @tag, @owner.id
    TaggingServices.new(@lst).tag_with @tag, @owner.id
  end

  def teardown

  end

  test "a list accepts recipes" do
    list = List.assert "Empty List", @owner
    assert_equal [], list.entities, "List not asserted with empty entities list"
    rcp = FactoryGirl.create(:recipe)
    refute list.stores?(rcp), "List shouldn't include entity before inclusion"
    list.store rcp
    assert list.stores?(rcp), "List should include entity after inclusion"
    list.save
    list.reload
    assert_nil list.ordering.first.entity(false) # Should be restored without the entity
    assert_equal rcp.id, list.ordering.first.id
    assert_equal rcp.class, list.ordering.first.klass
    assert list.stores?(rcp), "List should include entity after save and restore"
  end

=begin
  Actually, an entity isn't automatically tagged for the list when it's stored there. Normally, they're added manually from the set of tagged entities
  test "a recipe added to a list is tagged for it" do
    assert_equal @lst_name, @lst.name
    assert_equal @lst_name, @lst.name_tag.name
    ts = TaggingServices.new(@included)
    assert ts.exists?(@lst.name_tag, @owner.id)
  end
=end

=begin
# These tests will only become relevant if we restore the list's set of tags for including
  test "list accepts tag" do
    assert @lst.tags.exists?(id: @tag.id), "list doesn't include tag"
  end

  test "a list creates, saves and restores tag list" do
    tag1 = Tag.assert "Tag 1", userid: @owner.id
    tag2 = Tag.assert "Tag 2", userid: @owner.id, tagtype: :Ingredient
    @lst.tags = [tag1, tag2]
    assert_equal tag1, @lst.tags.first, "First tag not attached to list after assignment"
    assert_equal tag2, @lst.tags.last, "Last tag not attached to list after assignment"
    @lst.save
    @lst.reload
    assert_equal tag1, @lst.tags.first, "First tag not attached to list after save and restore"
    assert_equal tag2, @lst.tags.last, "Last tag not attached to list after save and restore"
  end
=end

  test "a list includes only its direct (explicit) tags" do
    refute ListServices.new(@lst).include?(@tagged, @owner.id, false), "List falsely says it includes recipe"
    assert ListServices.new(@lst).include?(@included, @owner.id), "List doesn't say it includes"
  end

  test "fetched entities include indirect entities (from subtags)" do
    assert ListServices.new(@lst).include?(@included, @owner.id), "List doesn't include one directly included"
    assert ListServices.new(@lst).include?(@tagged, @owner.id), "List doesn't include one indirectly included"
  end

  test "a list's entities are collected by its owner" do
    refute @tagged.collected?(@owner.id)
    assert @included.collected?(@owner.id)
  end

end
