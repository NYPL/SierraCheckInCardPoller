require_relative '../lib/pg_manager'
require_relative './spec_helper'


describe PSQLClient do
    describe :init do
        before (:each) {
            $kms_client = mock()
        }

        it "should create a connection object" do
            $kms_client.stubs(:decrypt).once.with('test_usr').returns('usr')
            $kms_client.stubs(:decrypt).once.with('test_pswd').returns('pswd')

            PG.stubs(:connect).once.with(
                host: 'test_host', port: '9999', dbname: 'test_db', user: 'usr', password: 'pswd'
            ).returns('mock_connection')

            test_client = PSQLClient.new

            expect(test_client.instance_variable_get(:@conn)).to eq('mock_connection')
        end
    end

    describe :exec_query do
        before (:each) {
            @mock_conn = mock()
            PG.stubs(:connect).returns(@mock_conn)

            $kms_client = mock()
            $kms_client.stubs(:decrypt)

            @test_client = PSQLClient.new
        }

        it "should execute a sql query and return the results if successful" do
            @mock_conn.stubs(:exec).once.with('test query').returns('test response')

            resp = @test_client.exec_query 'test query'

            expect(resp).to eq('test response')
        end

        it "should raise a PSQLError if an exception occurs during the query" do
            @mock_conn.stubs(:exec).once.raises(StandardError.new("Test db error"))

            expect { @test_client.send(:exec_query, 'test_query') }.to raise_error(PSQLError, "Cannot execute query against Sierra db, no rows retrieved")
        end
    end
end
