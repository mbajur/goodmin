# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2026_03_29_000000) do

  create_table "admin_users", force: :cascade do |t|
    t.string "email"
    t.text "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "another_admin_users", force: :cascade do |t|
    t.string "email"
    t.text "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "articles", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.boolean "published", default: false
    t.integer "admin_user_id"
    t.text "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_articles_on_admin_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.integer "article_id"
    t.string "title"
    t.text "body"
    t.index ["article_id"], name: "index_comments_on_article_id"
  end

  create_table "articles_magazines", id: false, force: :cascade do |t|
    t.integer "article_id", null: false
    t.integer "magazine_id", null: false
    t.index ["article_id", "magazine_id"], name: "index_articles_magazines_on_article_id_and_magazine_id"
  end

  create_table "magazines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "article_id"
    t.string "bio"
    t.string "website"
    t.index ["article_id"], name: "index_profiles_on_article_id"
  end

  add_foreign_key "comments", "articles"
  add_foreign_key "profiles", "articles"

  create_table "tags", force: :cascade do |t|
    t.integer "comment_id"
    t.string "name"
    t.index ["comment_id"], name: "index_tags_on_comment_id"
  end

  add_foreign_key "tags", "comments"
end
