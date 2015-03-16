class User
  extend Database
  attr_reader :id, :name, :password, :admin_status

  def initialize(id, name, password, admin_status = false)
    @id = id
    @name = name
    @password = password
    @admin_status = admin_status
  end

  def self.valid_sign_in?(input)
    return false if input.values.include?("")

    user = User.find_by(input["username"])
    if user.exists?
      sha256 = OpenSSL::Digest::SHA256.new
      input_password = [sha256.digest(input["password"])].pack('m')
      input["username"] == user.name && input_password == user.password
    else
      false
    end
  end

  def self.find_by(username)
    user_info = db_connection do |conn|
      sql_query = "SELECT * FROM users WHERE username = $1"
      conn.exec_params(sql_query, [username])
    end
    user_info = user_info.to_a[0] || {}
    User.new(user_info["id"], user_info["username"], user_info["password"], user_info["admin_status"])
  end

  def self.find(id)
    user_info = db_connection do |conn|
      sql_query = "SELECT * FROM users WHERE id = $1"
      conn.exec_params(sql_query, [id])
    end
    user_info = user_info.to_a[0] || {}
    User.new(user_info["id"], user_info["username"], user_info["password"])
  end

  def self.valid_registration?(input)
    if input.values.include?("") || input["password"] != input["confirm_password"]
      false
    else
      user = User.find_by(input["username"])
      !user.exists?
    end
  end

  def self.add(input)
    sha256 = OpenSSL::Digest::SHA256.new
    input_password = [sha256.digest(input["password"])].pack('m')
    user_info = db_connection do |conn|
      sql_query = "INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *"
      conn.exec_params(sql_query, [input["username"], input_password])
    end
    user_info = user_info.to_a[0]
    user = User.new(user_info["id"], user_info["username"], user_info["password"])
    user.assign_shared_homes
    user
  end

  def self.assign_home(input)
    db_connection do |conn|
      sql_query = "INSERT INTO user_homes (user_id, home_id) SELECT $1, $2
      WHERE NOT EXISTS(SELECT 1 FROM user_homes
      WHERE user_id = $1 AND home_id = $2)"
      conn.exec_params(sql_query, [input["user_id"], input["home_id"]])
    end
  end

  def self.unassign_home(input)
    db_connection do |conn|
      sql_query = "DELETE FROM user_homes WHERE user_id = $1 AND home_id = $2"
      conn.exec_params(sql_query, [input["user_id"], input["home_id"]])
    end
  end

  def self.all
    users_info = db_connection do |conn|
      conn.exec("SELECT * FROM users")
    end
    users = users_info.to_a.map do |user_info|
      User.new(user_info["id"], user_info["username"], user_info["password"], user_info["admin_status"])
    end
    users.delete_if { |user| user.admin_status == "t"}
    users
  end

  def exists?
    @id
  end

  def assign_shared_homes
    (1..4).each do |home_id|
      input = { "user_id" => @id, "home_id" => home_id }
      User.assign_home(input)
    end
  end
end
