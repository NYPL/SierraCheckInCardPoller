require 'nypl_ruby_util'

require_relative 'lib/pg_manager'
require_relative 'lib/sqlite_manager'
require_relative 'lib/s3_manager'

def init
    return if $initialized

    $logger = NYPLRubyUtil::NyplLogFormatter.new($stdout, level: ENV['LOG_LEVEL'])
    $kms_client = NYPLRubyUtil::KmsClient.new
    $pg_client = PSQLClient.new
    $sqlite_client = SQLITEClient.new
    $s3_client = S3Client.new

    $logger.debug 'Initialized function'
    $initialized = true
end

def handle_event(*)
    init

    $logger.info 'Loading recent updates from the Sierra database'

    # Create sqlite db in tmp
    $sqlite_client.create_table

    # Fetch check-in box rows from the Sierra db and store them in sqlite
    # Because there are 800k+ records in the db, the query is split into chunks
    # to prevent timeouts. Each chunk is written to the local db in order
    fetch_and_store_rows

    # Store the sqlite db in a s3 bucket
    $s3_client.store_data ENV['SQLITE_FILE']
end

def fetch_and_store_rows
    offset = 0
    limit = 100_000
    loop do
        $logger.info "Querying sierra for record batch #{offset}:#{limit}"
        box_rows = $pg_client.exec_query(ENV['DB_QUERY'], offset, limit)

        break unless box_rows.ntuples > 0

        store_rows box_rows
        offset += limit
    end
end

def store_rows(box_rows)
    fields = box_rows[0].keys
    rows = []
    box_rows.each do |row|
        rows << fields.map { |k| row[k] }

        next unless rows.length % 100 == 0

        $sqlite_client.insert_rows(fields, rows)
        rows = []
    end

    return unless rows.length % 100 != 0

    $sqlite_client.insert_rows(fields, rows)
end
