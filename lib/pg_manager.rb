p ENV['GEM_PATH']

require 'pg'

class PSQLClient
    def initialize
        @conn = PG.connect(
            host: ENV['DB_HOST'],
            port: ENV['DB_PORT'],
            dbname: ENV['DB_NAME'],
            user: $kms_client.decrypt(ENV['DB_USER']),
            password: $kms_client.decrypt(ENV['DB_PSWD'])
        )
    end

    def exec_query query
        $logger.info "Querying Sierra db for check-in boxes"
        $logger.debug "Executing query: #{query}"

        begin
            @conn.exec query
        rescue Exception => e
            $logger.error "Unable to query Sierra db for check-in rows", { :message => e.message }
            raise PSQLError "Cannot execute query against Sierra db, no rows retrieved"
        end
    end
end


class PSQLError < StandardError; end