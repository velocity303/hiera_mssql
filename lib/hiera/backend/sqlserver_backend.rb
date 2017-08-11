# Class sqlserver_backend
# Description: MS SQL back end to Hiera.
class Hiera
  module Backend
    class Sqlserver_backend
      def initialize
        @use_jdbc = defined?(JRUBY_VERSION) ? true : false 
        if @use_jdbc
          require 'jdbc/sqlserver'
          require 'java'
          require 'rubygems'
          require 'sqljdbc4.jar'
        else
          require 'rubygems'
          require 'tiny_tds'
        end

        Hiera.debug("sqlserver_backend initialized")
        Hiera.debug("JDBC mode #{@use_jdbc}")
      end


      def lookup(key, scope, order_override, resolution_type)

        Hiera.debug("sqlserver_backend invoked lookup")
        Hiera.debug("resolution type is #{resolution_type}")

        answer = nil

        # Parse the mssql query from the config, we also pass in key
        # to extra_data so this can be interpreted into the query 
        # string
        #
        queries = [ Config[:sqlserver][:query] ].flatten
        queries.map! { |q| Backend.parse_string(q, scope, {"key" => key}) }

        queries.each do |sqlserver_query|

          results = query(sqlserver_query)

          unless results.empty?
            case resolution_type
            when :array
              answer ||= []
              results.each do |ritem|
                answer << Backend.parse_answer(ritem, scope)
              end
            else
              answer = Backend.parse_answer(results[0], scope)
              break
            end
          end

        end
        answer
      end

      def query (sql)
        Hiera.debug("Executing SQL Query: #{sql}")

        data=[]
        sqlserver_host=Config[:sqlserver][:host]
        sqlserver_user=Config[:sqlserver][:user]
        sqlserver_pass=Config[:sqlserver][:pass]
        sqlserver_database=Config[:sqlserver][:database]
        sqlserver_instance=Config[:sqlserver][:instance]


        if @use_jdbc
          #
          # JDBC connection handling, this will be run under jRuby
          #
          Jdbc::Sqlserver.load_driver
          #Java::com.microsoft.sqlserver.jdbc.SQLServerDriver
          url = "jdbc:sqlserver://#{sqlserver_host}:1433;instanceName=#{sqlserver_instance};databaseName=#{sqlserver_database}"
          props = java.util.Properties.new
          props.set_property :user, sqlserver_user
          props.set_property :password, sqlserver_pass
          driver = Java::com.microsoft.sqlserver.jdbc.SQLServerDriver.new
          conn = driver.connect(url,props)
          statement = conn.create_statement
          res = statement.execute_query(sql)
          md = res.getMetaData
          numcols = md.getColumnCount
          Hiera.debug("MS sql Query returned #{numcols} rows")

          while ( res.next ) do
            if numcols < 2
              Hiera.debug("MS sql value : #{res.getString(1)}")
              data << res.getString(1)
            else
              row = {}
              (1..numcols).each do |c|
                row[md.getColumnName(c)] = res.getString(c)
              end
              data << row
            end
          end
        else
          client = TinyTds::Client.new username: "#{sqlserver_user}", password: "#{sqlserver_pass}", host: "#{sqlserver_host}", database: "#{sqlserver_database}"
          res = client.execute(sql)

          res.each do |row|
            data << row
          end
        end
        return data
      end
    end
  end
end
