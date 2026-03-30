require "test_helper"

class DeepNestedResourcesTest < ActionDispatch::IntegrationTest
  def test_list_deep_nested_resources
    article = Article.create! title: "foo"
    comment = Comment.create! title: "bar", article: article, tags: [
      Tag.new(name: "baz")
    ]

    visit article_comment_tags_path(article, comment)

    assert page.has_content? "baz"
  end

  def test_create_deep_nested_resource
    article = Article.create! title: "foo"
    comment = Comment.create! title: "bar", article: article

    visit new_article_comment_tag_path(article, comment)

    fill_in "Name", with: "baz"
    click_button "Create Tag"

    assert_equal article_comment_tag_path(article, comment, Tag.last), current_path
  end

  def test_has_many_link_uses_correct_nested_path
    article = Article.create! title: "foo"
    comment = Comment.create! title: "bar", article: article

    visit article_comment_path(article, comment)

    expected_path = article_comment_tags_path(article, comment)
    assert page.has_css?("a[href='#{expected_path}']", visible: :all)
  end
end
