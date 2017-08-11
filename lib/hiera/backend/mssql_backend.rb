# Class Mssql_backend
# Description: MS SQL back end to Hiera.
class Hiera
  module Backend
    class Mssql_backend
      def initialize
        @use_jdbc = defined?(JRUBY_VERSION) ? true : false 
        if @use_jdbc
          require 'jdbc/sqlserver'
          require 'java'
          require 'rubygems'
          require 'sqljdbc4.jar'
        else
          require 'rubygems'
	        require 'sequel'
          require 'tiny_tds'
        end

        Hiera.debug("mssql_backend initialized")
        Hiera.debug("JDBC mode #{@use_jdbc}")
      end


      def lookup(key, scope, order_override, resolution_type)

        Hiera.debug("mssql_backend invoked lookup")
        Hiera.debug("resolution type is #{resolution_type}")

        answer = nil

        # Parse the mssql query from the config, we also pass in key
        # to extra_data so this can be interpreted into the query 
        # string
        #
        queries = [ Config[:mssql][:query] ].flatten
        queries.map! { |q| Backend.parse_string(q, scope, {"key" => key}) }

        queries.each do |mssql_query|

          results = query(mssql_query)

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
        mssql_host=Config[:mssql][:host]
        mssql_user=Config[:mssql][:user]
        mssql_pass=Config[:mssql][:pass]
        mssql_database=Config[:mssql][:database]
        mssql_instance=Config[:mssql][:instance]


        if @use_jdbc
          #
          # JDBC connection handling, this will be run under jRuby
          #
          Jdbc::Sqlserver.load_driver
          #Java::com.microsoft.sqlserver.jdbc.SQLServerDriver
          url = "jdbc:sqlserver://#{mssql_host}:1433;instanceName=#{mssql_instance};databaseName=#{mssql_database}"
          props = java.util.Properties.new
          props.set_property :user, mssql_user
          props.set_property :password, mssql_pass
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
          client = TinyTds::Client.new username: "#{mssql_user}", password: "#{mssql_pass}", host: "#{mssql_host}", database: "#{mssql_database}"
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
