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

ActiveRecord::Schema[8.1].define(version: 2026_05_01_000000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.datetime "last_used_at"
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.string "model_id"
    t.integer "output_tokens"
    t.string "role"
    t.integer "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_chat_messages_on_chat_id"
    t.index ["tool_call_id"], name: "index_chat_messages_on_tool_call_id"
  end

  create_table "chats", force: :cascade do |t|
    t.integer "chatable_id", null: false
    t.string "chatable_type", null: false
    t.datetime "created_at", null: false
    t.string "model_id"
    t.datetime "updated_at", null: false
    t.index ["chatable_type", "chatable_id"], name: "index_chats_on_chatable"
  end

  create_table "global_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["name"], name: "index_global_settings_on_name", unique: true
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

# Could not dump table "meal_vectors_vector_chunks00" because of following StandardError
#   Unknown type '' for column 'rowid'


  create_table "meals", force: :cascade do |t|
    t.integer "calories"
    t.float "carbs"
    t.datetime "created_at", null: false
    t.text "description"
    t.float "fats"
    t.string "meal_name"
    t.string "prompt"
    t.float "proteins"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_meals_on_user_id"
  end

  create_table "nutrition_analyses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_end"
    t.date "date_start"
    t.datetime "executed_at"
    t.string "status", default: "completed"
    t.text "text"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_nutrition_analyses_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

# Could not dump table "query_embeddings_vector_chunks00" because of following StandardError
#   Unknown type '' for column 'rowid'


  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.json "arguments", default: {}
    t.integer "chat_message_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_message_id"], name: "index_tool_calls_on_chat_message_id"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id"
  end

  create_table "user_meals", force: :cascade do |t|
    t.datetime "consumed_at", null: false
    t.datetime "created_at", null: false
    t.string "error"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "meal_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["meal_id"], name: "index_user_meals_on_meal_id"
    t.index ["user_id"], name: "index_user_meals_on_user_id"
  end

  create_table "user_profiles", force: :cascade do |t|
    t.integer "age"
    t.datetime "created_at", null: false
    t.boolean "enable_location_tracking", default: false
    t.float "height"
    t.string "muscle_building"
    t.string "physical_activity"
    t.string "sex"
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.float "weight"
    t.string "weight_goals"
    t.index ["user_id"], name: "index_user_profiles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_keys", "users"
  add_foreign_key "chat_messages", "chats"
  add_foreign_key "invites", "users"
  add_foreign_key "meals", "users"
  add_foreign_key "nutrition_analyses", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tool_calls", "chat_messages"
  add_foreign_key "user_meals", "meals"
  add_foreign_key "user_meals", "users"
  add_foreign_key "user_profiles", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "meal_vectors", "vec0", ["meal_id integer primary key", "embedding float[1536] distance_metric=cosine"]
  create_virtual_table "query_embeddings", "vec0", ["query_text text primary key", "embedding float[1536] distance_metric=cosine"]
end
