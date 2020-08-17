require 'nypl_ruby_util'

require_relative 'lib/pg_manager'
require_relative 'lib/sqlite_manager'
require_relative 'lib/s3_manager'

def init
    return if $initialized

    $logger = NYPLRubyUtil::NyplLogFormatter.new(STDOUT, level: ENV['LOG_LEVEL'])
    $kms_client = NYPLRubyUtil::KmsClient.new
    $pg_client = PSQLClient.new
    $sqlite_client = SQLITEClient.new
    $s3_client = S3Client.new

    $logger.debug "Initialized function"
    $initialized = true
end


def handle_event(event:, context:)
    init

    $logger.info "Loading recent updates from the Sierra database"

    # Create sqlite db in tmp
    $sqlite_client.create_table

    # Fetch check-in box rows from the Sierra db
    box_rows = fetch_rows

    # Store rows in sqlite db
    store_rows box_rows

    # Store the sqlite db in a s3 bucket
    $s3_client.store_data ENV['SQLITE_FILE']
end

def fetch_rows
    card_rows = $pg_client.exec_query ENV['DB_QUERY']
end

def store_rows box_rows
    fields = box_rows[0].keys
    rows = []
    box_rows.each do |row|
        rows << fields.map { |k| row[k] }
        if rows.length % 100 == 0
            $sqlite_client.insert_rows(fields, rows)
            rows = []
        end
    end

    if rows.length % 100 != 0
        $sqlite_client.insert_rows(fields, rows)
    end
end
