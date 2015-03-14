module Database
  def db_connection
    connection_settings = { dbname: ENV["DATABASE_NAME"] || "foster_homes" }

    if ENV["DATABASE_HOST"]
      connection_settings[:host] = ENV["DATABASE_HOST"]
    end

    if ENV["DATABASE_USER"]
      connection_settings[:user] = ENV["DATABASE_USER"]
    end

    if ENV["DATABASE_PASS"]
      connection_settings[:password] = ENV["DATABASE_PASS"]
    end

    begin
      connection = PG.connect(connection_settings)
      yield(connection)
    ensure
      connection.close
    end
  end
end
