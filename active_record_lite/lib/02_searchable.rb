require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    p_keys = params.keys.map { |el| "#{el} = ?"}.join(" AND ")
    p_values = params.values
    table = DBConnection.execute(<<-SQL, *p_values)
  SELECT
    *
  FROM
    #{table_name}
  WHERE
    #{p_keys}
  SQL
  parse_all(table)
  end
end

class SQLObject
  extend Searchable
end
