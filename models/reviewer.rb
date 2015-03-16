class Reviewer
  extend Database
  attr_reader :id, :name, :type
  TYPE = {"1" => "Youth", "2" => "Parent", "3" => "Worker"}

  def initialize(id, name, type)
    @id = id
    @name = name
    @type = type
  end

  def self.add(input)
    input["person_type"] = TYPE[input["form_id"]]
    db_connection do |conn|
      sql_query = "INSERT INTO reviewers (name, type) SELECT $1::varchar, $2::varchar
      WHERE NOT EXISTS(SELECT 1 FROM reviewers WHERE name = $1 AND type = $2)"
      conn.exec_params(sql_query, [input["reviewer"], input["person_type"]])
    end

    reviewer_id = db_connection do |conn|
      sql_query = "SELECT id FROM reviewers WHERE name = $1 AND type = $2"
      conn.exec_params(sql_query, [input["reviewer"], input["person_type"]])
    end
    reviewer_id = reviewer_id.to_a[0]["id"]
    self.find(reviewer_id)
  end

  def self.find(id)
    reviewer_info = db_connection do |conn|
      sql_query = "SELECT * FROM reviewers WHERE id = $1"
      conn.exec_params(sql_query, [id])
    end
    reviewer_info = reviewer_info.to_a[0]
    Reviewer.new(reviewer_info["id"], reviewer_info["name"], reviewer_info["type"])
  end
end
