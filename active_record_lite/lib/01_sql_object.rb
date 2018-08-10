require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @col if @col
    columns = DBConnection.execute2(<<-SQL)
  SELECT
    *
  FROM
    #{self.table_name}
  SQL

  @col = columns.first.map { |column| column.to_sym }

  end

  def self.finalize!
    self.columns.each do |column|
        define_method(column) do
          self.attributes[column]
        end

        define_method("#{column}=") do |val|
          self.attributes[column] = val
        end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    "#{self.to_s.underscore}s"
    # @table_name ||= "#{self}".to_s.tableize
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    all.map { |el| self.new(el) }
  end

  def self.parse_all(results)
    results.map { |el| self.new(el) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL

    results.map { |el| self.new(el) }.first
  end

  def initialize(params = {})

    params.each do |key, value|
      k_sym = key.to_sym
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(k_sym)
      send("#{k_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |el| send(el) }
  end

  def insert
    col_names = self.class.columns[1..-1].join(',')
    question_marks = (["?"] * (self.class.columns[1..-1].length)).join(',')

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set = self.class.columns[1..-1].map { |el| "#{el} = ?"}.join(',')
    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      UPDATE
        #{self.class.table_name}
      SET
        #{set}
      WHERE
        id = #{attribute_values.first}
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
