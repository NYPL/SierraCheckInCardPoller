require_relative '../app'
require_relative './spec_helper'


describe 'handler' do
    describe :init do
        before(:each) {
            $initialized = false

            @kms_mock = mock()
            @kms_mock.stubs(:decrypt)
            NYPLRubyUtil::KmsClient.stubs(:new).returns(@kms_mock)
            @pg_mock = mock()
            PSQLClient.stubs(:new).returns(@pg_mock)
            @sqlite_mock = mock()
            SQLITEClient.stubs(:new).returns(@sqlite_mock)
            @s3_mock = mock()
            S3Client.stubs(:new).returns(@s3_mock)
        }

        after(:each) {
            @kms_mock.unstub(:decrypt)
        }

        it "should invoke clients and logger from the ruby utils gem" do
            init

            expect($kms_client).to eq(@kms_mock)
            expect($pg_client).to eq(@pg_mock)
            expect($sqlite_client).to eq(@sqlite_mock)
            expect($s3_client).to eq(@s3_mock)
            expect($initialized).to eq(true)
        end
     end

    describe :handle_event do
        before(:each) {
            mock_sqlite = mock()
            $sqlite_client = mock_sqlite

            mock_s3 = mock()
            $s3_client = mock_s3
        }
        it "should invoke validate_record and send_record_to_stream for each record" do
            self.stubs(:init).once
            $sqlite_client.stubs(:create_table).once
            self.stubs(:fetch_rows).once.returns([1, 2, 3])
            self.stubs(:store_rows).once.with([1, 2, 3])
            $s3_client.stubs(:store_data).once.with('test.sql')

            handle_event(event: {}, context: {})
        end
    end

    describe :fetch_rows do
        before(:each) {
            mock_pg = mock()
            $pg_client = mock_pg
        }

        it "should execute a query against the postgres database" do
            $pg_client.stubs(:exec_query).once.with('TEST QUERY')

            fetch_rows
        end
    end

    describe :store_rows do
        before(:each) {
            mock_sqlite = mock()
            $sqlite_client = mock_sqlite
        }

        it "should insert all rows in one batch if fewer than 100" do
            row_arr = (0..99).to_a.map { |i| { 'id' => i } }
            $sqlite_client.stubs(:insert_rows).once.with(['id'], row_arr.map { |i| [i['id']] })

            store_rows row_arr
        end

        it "should insert all rows in three batches if more than 200 and less than 300" do
            row_arr = (0..250).to_a.map { |i| { 'id' => i } }
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (0..99).to_a.map { |i| [i] })
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (100..199).to_a.map { |i| [i] })
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (200..250).to_a.map { |i| [i] })
            
            store_rows row_arr
        end
    end
end