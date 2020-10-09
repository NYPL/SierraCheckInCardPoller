require 'sqlite3'

# Client for creating and updating local sqlite3 database
class SQLITEClient
    def initialize
        @db = SQLite3::Database.new "/tmp/#{ENV['SQLITE_FILE']}"
    end

    def create_table
        $logger.info 'Creating boxes table in sqlite database'

        @db.execute <<-BOXES
            create table boxes (
                id int UNIQUE,
                holding_record_id int,
                record_num int,
                holding_record_cardlink_id int,
                box_count int,
                enum_level_a varchar(10),
                enum_level_b varchar(10),
                enum_level_c varchar(10),
                enum_level_d varchar(10),
                enum_level_e varchar(10),
                enum_level_f varchar(10),
                enum_level_g varchar(10),
                enum_level_h varchar(10),
                chron_level_i int,
                chron_level_j int,
                chron_level_k int,
                chron_level_l int,
                chron_level_m int,
                chron_level_i_trans_date int,
                chron_level_j_trans_date int,
                chron_level_k_trans_date int,
                chron_level_l_trans_date int,
                chron_level_m_trans_date int,
                note varchar(500),
                box_status_code char(1),
                claim_cnt int,
                copies_cnt int,
                url varchar(500),
                is_suppressed bool,
                staff_note varchar(500)
            );
        BOXES
    end

    def insert_rows(fields, rows)
        $logger.info "Inserting #{rows.length} rows into sqlite db"

        insert_stmt = _generate_row_statements rows

        return if insert_stmt.length == 0

        begin
            @db.execute("INSERT OR IGNORE INTO boxes (#{fields.join(', ')}) VALUES #{insert_stmt};")
        rescue StandardError => e
            $logger.debug insert_stmt
            $logger.error 'Unable to insert rows into boxes table', { code: e.code }
            raise SqliteError, 'Failed to insert row into sqlite db'
        end
    end

    private

    def _generate_row_statements(rows)
        rows.map do |row|
            next if row[0].nil?

            $logger.debug "Inserting row# #{row[0]} into sqlite database"
            _prepare_row row
        end.compact.join(', ')
    end

    def _prepare_row(row)
        row_arr = row.map do |r|
            r ? "'#{r.gsub(/'/, "''")}'" : 'null'
        end

        "(#{row_arr.join(', ')})"
    end
end

class SqliteError < StandardError; end
