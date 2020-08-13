require 'sqlite3'


class SQLITEClient
    def initialize
        @db = SQLite3::Database.new "/tmp/#{ENV['SQLITE_FILE']}"
    end

    def create_table
        $logger.info "Creating boxes table in sqlite database"

        @db.execute <<-BOXES
            create table boxes (
                id int,
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
                note varchar(250),
                box_status_code char(1),
                claim_cnt int,
                copies_cnt int,
                url varchar(250),
                is_suppressed bool,
                staff_note varchar(250)
            );
        BOXES
    end

    def insert_row fields, rows
       $logger.info "Inserting #{rows.length} rows into sqlite db" 
        
       insert_stmt = _generate_row_statements rows

        begin
            @db.execute("INSERT INTO boxes (#{fields.join(', ')}) VALUES #{insert_stmt};")
        rescue Exception => e
            $logger.error "Unable to insert rows into boxes table", { "code" => e.code }
            raise SqliteError.new "Failed to insert row into sqlite db"
        end
    end

    private 

    def _generate_row_statements rows
        insert_stmt = rows.map { |row|
            $logger.debug "Inserting row# #{row[0]} into sqlite database"
            _prepare_row row
        }.join(', ')
    end

    def _prepare_row row
        row_arr = row.map { |r|
            r ? "'#{r.gsub(/'/, "\\'")}'" : 'null'
        }

        return "(#{row_arr.join(', ')})"
    end
end


class SqliteError < StandardError; end