require_relative '../app'
require_relative './spec_helper'

describe 'handler' do
    describe :init do
        before(:each) do
            $initialized = false

            @kms_mock = mock
            @kms_mock.stubs(:decrypt)
            NYPLRubyUtil::KmsClient.stubs(:new).returns(@kms_mock)
            @pg_mock = mock
            PSQLClient.stubs(:new).returns(@pg_mock)
            @sqlite_mock = mock
            SQLITEClient.stubs(:new).returns(@sqlite_mock)
            @s3_mock = mock
            S3Client.stubs(:new).returns(@s3_mock)
        end

        after(:each) do
            @kms_mock.unstub(:decrypt)
        end

        it 'should invoke clients and logger from the ruby utils gem' do
            init

            expect($kms_client).to eq(@kms_mock)
            expect($pg_client).to eq(@pg_mock)
            expect($sqlite_client).to eq(@sqlite_mock)
            expect($s3_client).to eq(@s3_mock)
            expect($initialized).to eq(true)
        end
    end

    describe :handle_event do
        before(:each) do
            mock_sqlite = mock
            $sqlite_client = mock_sqlite

            mock_s3 = mock
            $s3_client = mock_s3
        end

        it 'should invoke create_table, fetch_and_store_rows and store_data' do
            stubs(:init).once
            $sqlite_client.stubs(:create_table).once
            stubs(:fetch_and_store_rows).once
            $s3_client.stubs(:store_data).once.with('test.sql')

            handle_event(event: {}, context: {})
        end
    end

    describe :fetch_and_store_rows do
        before(:each) do
            mock_pg = mock
            $pg_client = mock_pg
        end

        it 'should execute batch queries against the postgres database until no rows returned' do
            response_with_rows = mock
            response_with_rows.stubs(:ntuples).returns(100)

            response_without_rows = mock
            response_without_rows.stubs(:ntuples).returns(0)

            $pg_client.stubs(:exec_query).once.with('TEST QUERY', offset: 0, limit: 100_000).returns(response_with_rows)
            $pg_client.stubs(:exec_query).once.with('TEST QUERY', offset: 100_000, limit: 100_000)\
                .returns(response_without_rows)

            stubs(:store_rows).once.with(response_with_rows)

            fetch_and_store_rows
        end
    end

    describe :store_rows do
        before(:each) do
            mock_sqlite = mock
            $sqlite_client = mock_sqlite
        end

        it 'should insert all rows in one batch if fewer than 100' do
            row_arr = (0..99).to_a.map { |i| { 'id' => i } }
            $sqlite_client.stubs(:insert_rows).once.with(['id'], row_arr.map { |i| [i['id']] })

            store_rows row_arr
        end

        it 'should insert all rows in three batches if more than 200 and less than 300' do
            row_arr = (0..250).to_a.map { |i| { 'id' => i } }
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (0..99).to_a.map { |i| [i] })
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (100..199).to_a.map { |i| [i] })
            $sqlite_client.stubs(:insert_rows).once.with(['id'], (200..250).to_a.map { |i| [i] })

            store_rows row_arr
        end
    end
end
