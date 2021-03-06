class Home
  extend Database
  attr_reader :id, :name, :reviews

  def initialize(id, name, reviews = [])
    @id = id
    @name = name
    @reviews = reviews
  end

  def self.all(user_id = nil)
    if user_id
      homes_info = db_connection do |conn|
        sql_query = "SELECT homes.* FROM user_homes
        JOIN homes ON user_homes.home_id = homes.id
        WHERE user_homes.user_id = $1"
        conn.exec_params(sql_query, [user_id])
      end
    else
      homes_info = db_connection do |conn|
        conn.exec("SELECT * FROM homes")
      end
    end
    homes = homes_info.to_a.map do |home_info|
      Home.new(home_info["id"], home_info["name"])
    end
    homes
  end

  def self.find(id)
    reviews_info = db_connection do |conn|
      sql_query = "SELECT reviews.review_date, reviews.rating,
      reviews.comment, reviews.reviewer_id, reviewers.name AS reviewer,
      reviewers.type AS person_type, homes.name FROM reviews
      JOIN reviewers ON reviews.reviewer_id = reviewers.id
      JOIN homes ON reviews.home_id = homes.id
      WHERE reviews.home_id = $1 ORDER BY
      reviews.review_date DESC, reviews.ts DESC"
      conn.exec_params(sql_query, [id])
    end
    reviews_info = reviews_info.to_a
    reviews_info = [{}] unless reviews_info[0]
    home_name = reviews_info[0]["name"]
    reviews = reviews_info.map do |review|
      reviewer = Reviewer.new(review["reviewer_id"], review["reviewer"], review["person_type"])
      Review.new(review["review_date"], review["rating"], review["comment"], reviewer)
    end
    Home.new(id, home_name, reviews)
  end

  def self.find_data(id)
    home = self.find(id)
    reviews = home.reviews
    reviews = reviews.sort_by { |review| review.date }

    dates = reviews.inject([]) do |dates, review|
      dates << review.date unless dates.include?(review.date)
      dates
    end

    scores = reviews.inject({}) do |scores, review|
      reviewer_info = "#{review.reviewer.name} (#{review.reviewer.type})"
      scores[reviewer_info] = {} unless scores[reviewer_info]
      scores[reviewer_info][review.date] = review.rating.to_i
      scores
    end

    data = scores.inject([]) do |data, (reviewer, scores_hash)|
      reviewer_data = [reviewer]
      dates.each { |date| reviewer_data << scores_hash[date] }
      data << reviewer_data
    end

    data.unshift(['Dates', dates].flatten)
    data.transpose
  end

  def self.add(input)
    name = input["home_name"]
    db_connection do |conn|
      sql_query = "INSERT INTO homes (name) SELECT $1::varchar
      WHERE NOT EXISTS(SELECT 1 FROM homes WHERE name = $1)"
      conn.exec_params(sql_query, [name])
    end
  end

  def self.delete(input)
    home_id = input["home_id"]
    db_connection do |conn|
      sql_query1 = "DELETE FROM user_homes WHERE home_id = $1"
      conn.exec_params(sql_query1, [home_id])
      sql_query2 = "DELETE FROM reviews WHERE home_id = $1"
      conn.exec_params(sql_query2, [home_id])
      sql_query3 = "DELETE FROM homes WHERE id = $1"
      conn.exec_params(sql_query3, [home_id])
    end
  end

  def self.all_data(user_id)
    homes = all(user_id)
    homes.map { |home| {"id" => home.id, "name" => home.name} }
  end
end
