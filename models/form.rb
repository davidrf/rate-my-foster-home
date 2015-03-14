class Form
  extend Database
  attr_reader :id, :name, :question

  def initialize(id, name, question = nil)
    @id = id
    @name = name
    @question = question
  end

  def self.all
    forms_info = db_connection do |conn|
      conn.exec("SELECT id, name FROM forms")
    end
    forms = forms_info.to_a.map do |form_info|
      Home.new(form_info["id"], form_info["name"])
    end
    forms
  end

  def self.find(id)
    form_info = db_connection do |conn|
      sql_query = "SELECT * FROM forms WHERE id = $1;"
      conn.exec_params(sql_query, [id])
    end
    form_info = form_info.to_a[0]
    Form.new(form_info["id"], form_info["name"], form_info["question"])
  end

  def self.valid_submission?(input)
    !input["reviewer"].empty?
  end
end
