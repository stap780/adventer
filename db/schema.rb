# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_04_07_150346) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.string "name"
    t.string "middlename"
    t.string "surname"
    t.string "phone"
    t.string "email"
    t.integer "zip"
    t.string "state"
    t.string "city"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "insid"
  end

  create_table "clients_companies", id: false, force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "company_id", null: false
    t.index ["client_id", "company_id"], name: "index_clients_companies_on_client_id_and_company_id"
    t.index ["company_id", "client_id"], name: "index_clients_companies_on_company_id_and_client_id"
  end

  create_table "companies", force: :cascade do |t|
    t.boolean "our_company"
    t.string "title"
    t.string "fulltitle"
    t.string "uraddress"
    t.string "factaddress"
    t.bigint "inn"
    t.bigint "kpp"
    t.bigint "ogrn"
    t.bigint "okpo"
    t.bigint "bik"
    t.string "banktitle"
    t.string "bankaccount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "excel_prices", force: :cascade do |t|
    t.string "title"
    t.string "link"
    t.string "price_move"
    t.integer "price_shift"
    t.string "price_points"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "file_status"
    t.boolean "rrc"
    t.boolean "our_product"
  end

  create_table "homes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kp_products", force: :cascade do |t|
    t.integer "quantity"
    t.decimal "price"
    t.decimal "sum"
    t.bigint "kp_id"
    t.bigint "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "desc"
    t.string "sku"
    t.index ["kp_id"], name: "index_kp_products_on_kp_id"
    t.index ["product_id"], name: "index_kp_products_on_product_id"
  end

  create_table "kps", force: :cascade do |t|
    t.string "vid"
    t.string "status"
    t.string "title"
    t.bigint "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "extra", precision: 8, scale: 2
    t.string "comment"
    t.index ["order_id"], name: "index_kps_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "status"
    t.integer "number"
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "company_id"
    t.integer "companykp1_id"
    t.integer "companykp2_id"
    t.integer "companykp3_id"
    t.bigint "user_id"
    t.integer "insid"
    t.string "number_adventer"
    t.index ["company_id"], name: "index_orders_on_company_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "sku"
    t.string "title"
    t.string "desc"
    t.integer "quantity"
    t.decimal "costprice"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "insid"
    t.integer "insvarid"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.bigint "role_id"
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "kp_products", "kps"
  add_foreign_key "kp_products", "products"
  add_foreign_key "kps", "orders"
  add_foreign_key "orders", "companies"
  add_foreign_key "orders", "users"
  add_foreign_key "users", "roles"
end
