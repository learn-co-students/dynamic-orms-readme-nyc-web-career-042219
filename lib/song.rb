require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song

  #* grabs the name of the table, self refers to the class.
  def self.table_name
    #* a sql table name and a class name share a pattern.
    #* turn to a string, lowercase it, then pluralize it.
    self.to_s.downcase.pluralize
  end

  #* grabs the name of the columns
  def self.column_names
    #* returns results of sqlite3 query in hash form 
    #* instead of in array form.
    DB[:conn].results_as_hash = true

    #* pass in the table name using self.table_name
    #* pragma table_info takes in an argument of a table name.
    #* it returns all the info on each column. 
    sql = "pragma table_info('#{table_name}')"

    #@ table_info = a hash because of results_as_hash = true
    table_info = DB[:conn].execute(sql)
    column_names = []
    #* each row contains column information including its name
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  #* creates attr_accessors for each column in the database
  #* iterate over each column_name gather from self.column_names
  self.column_names.each do |col_name|
    #* turn each col_name into a symbol
    attr_accessor col_name.to_sym
  end

  #* using a hash means we can take any number of parameters as a 
  #* single argument.
  def initialize(options={})
    #@ property = key, @value = value
    options.each do |property, value|
      #* uses the setter method made by the attr_accessor to assign
      #* the initial value.
      self.send("#{property}=", value)
    end
  end

  def save
    #* Inserts values into a specfic table and column
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    #* Assigns the id.
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  #* gives the instance access to the table name by letting it call
  #* the class method.
  def table_name_for_insert
    self.class.table_name
  end

  #* gathers the values need for inserting into the save method.
  def values_for_insert
    #@ values is an array of values to be passed into the db.
    values = []
    #* iterate over each column name
    self.class.column_names.each do |col_name|
      #* gets the values from the column name assuming its not nil.
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    #* coverts the array into a string separated by ','
    values.join(", ")
  end

  #* gives the instance access to the column names by letting it call
  #* the class method. it also deletes the 'id' column since we want 
  #* to let the database assign it. lastly it joins the column names
  #* into a string.
  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  #* allows the class to search for a name equal to a name attribute.
  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



