require_relative '../lib/sqlite_manager'
require_relative './spec_helper'


describe SQLITEClient do
    describe :initialize do
        it "should initialize a database in the /tmp directory" do
            SQLite3::Database.stubs(:new).once.with('/tmp/test.sql').returns('test_db')
            test_client = SQLITEClient.new

            expect(test_client.instance_variable_get(:@db)).to eq('test_db')
        end
    end

    describe :create_table do
        before (:each) {
            SQLite3::Database.stubs(:new).once.with('/tmp/test.sql').returns(mock())
            @test_client = SQLITEClient.new
        }

        it "should execute a query to create the boxes table" do
            @test_client.instance_variable_get(:@db).stubs(:execute).once

            @test_client.create_table
        end
    end

    describe :insert_rows do
        before (:each) {
            SQLite3::Database.stubs(:new).once.with('/tmp/test.sql').returns(mock())
            @test_client = SQLITEClient.new
        }

        it "should execute insert statement for all rows" do
            @test_client.instance_variable_get(:@db).stubs(:execute).once.with(
                "INSERT INTO boxes (id) VALUES ('1'), ('2'), ('3');"
            )
            @test_client.stubs(:_generate_row_statements).once.with([1, 2, 3]).returns(
                "('1'), ('2'), ('3')"
            )

            @test_client.insert_rows(['id'], [1, 2, 3])
        end

        it "should raise an exception if it is unable to insert the rows" do
            @test_client.instance_variable_get(:@db).stubs(:execute).once.with(
                "INSERT INTO boxes (id) VALUES ('1'), ('2'), ('3');"
            ).raises(SQLite3::Exception.new('test error'))
            @test_client.stubs(:_generate_row_statements).once.with([1, 2, 3]).returns(
                "('1'), ('2'), ('3')"
            )

            expect { @test_client.send(:insert_rows, ['id'], [1, 2, 3])}.to raise_error(SqliteError, "Failed to insert row into sqlite db")
        end
    end

    describe :_generate_row_statements do
        before (:each) {
            SQLite3::Database.stubs(:new).once.with('/tmp/test.sql').returns(mock())
            @test_client = SQLITEClient.new
        }

        it "should create an array of entries from the rows argument" do
            @test_client.stubs(:_prepare_row).once.with(1).returns("('1')")
            @test_client.stubs(:_prepare_row).once.with(2).returns("('2')")
            @test_client.stubs(:_prepare_row).once.with(3).returns("('3')")

            test_insert = @test_client.send(:_generate_row_statements, [1, 2, 3])
            expect(test_insert).to eq("('1'), ('2'), ('3')")
        end
    end

    describe :_prepare_row do
        before (:each) {
            SQLite3::Database.stubs(:new).once.with('/tmp/test.sql').returns(mock())
            @test_client = SQLITEClient.new
        }

        it "should quote all values passed in" do
            test_row = @test_client.send(:_prepare_row, ['1', 'test', 'value'])

            expect(test_row).to eq("('1', 'test', 'value')")
        end

        it "should replate nil values with unquoted null values" do
            test_row = @test_client.send(:_prepare_row, ['1', nil, '2', nil])

            expect(test_row).to eq("('1', null, '2', null)")
        end
    end
end