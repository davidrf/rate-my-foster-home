class Review
  extend Database
  attr_reader :date, :rating, :comment, :reviewer

  def initialize(date, rating, comment, reviewer)
    @date = date
    @rating = rating
    @comment = comment
    @reviewer = reviewer
  end

  def self.add(input)
    sql_query1 = "DELETE FROM reviews WHERE review_date = $1 AND reviewer_id = $2
    AND home_id = $3"
    data1 = [input["review_date"], input["reviewer_id"], input["home_id"]]

    sql_query2 = "INSERT INTO reviews (review_date, rating, comment, reviewer_id, home_id)
    VALUES ($1, $2, $3, $4, $5) "
    data2 = [input["review_date"], input["rating"], input["explanation"], input["reviewer_id"], input["home_id"]]

    db_connection do |conn|
      conn.exec_params(sql_query1, data1)
      conn.exec_params(sql_query2, data2)
    end
  end
end
