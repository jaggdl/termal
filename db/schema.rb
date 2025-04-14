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

ActiveRecord::Schema[8.0].define(version: 2025_04_14_050434) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "global_settings", force: :cascade do |t|
    t.string "name", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_global_settings_on_name", unique: true
  end

  create_table "invites", force: :cascade do |t|
    t.string "token"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "meal_vectors_chunks", primary_key: "chunk_id", force: :cascade do |t|
    t.integer "size", null: false
    t.binary "validity", null: false
    t.binary "rowids", null: false
  end

# Could not dump table "meal_vectors_info" because of following StandardError
#   Unknown type 'ANY' for column 'value'


# Could not dump table "meal_vectors_rowids" because of following StandardError
#   Unknown type '' for column 'id'


# Could not dump table "meal_vectors_vector_chunks00" because of following StandardError
#   Unknown type '' for column 'rowid'


  create_table "meals", force: :cascade do |t|
    t.string "meal_name"
    t.integer "calories"
    t.float "fats"
    t.float "proteins"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "carbs"
    t.float "fiber"
    t.integer "sodium"
    t.float "sugar"
    t.integer "cholesterol"
    t.text "description"
    t.string "prompt"
  end

  create_table "nutrition_analyses", force: :cascade do |t|
    t.text "text"
    t.date "date_start"
    t.date "date_end"
    t.datetime "executed_at"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "completed"
    t.index ["user_id"], name: "index_nutrition_analyses_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "endpoint"
    t.string "p256dh_key"
    t.string "auth_key"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_meals", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "meal_id", null: false
    t.datetime "consumed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "error"
    t.index ["meal_id"], name: "index_user_meals_on_meal_id"
    t.index ["user_id"], name: "index_user_meals_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.integer "age"
    t.string "sex"
    t.float "weight"
    t.float "height"
    t.string "physical_activity"
    t.string "weight_goals"
    t.string "muscle_building"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timezone"
    t.boolean "dark_mode", default: false
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "invites", "users"
  add_foreign_key "nutrition_analyses", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_meals", "meals"
  add_foreign_key "user_meals", "users"
  add_foreign_key "user_profiles", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "meal_vectors", "vec0", ["meal_id integer primary key", "embedding float[1536] distance_metric=cosine"]
end
