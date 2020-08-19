require_relative '../lib/s3_manager'
require_relative './spec_helper'

describe S3Client do
    describe :initialize do
        it 'should create a s3 client object' do
            mock_client = mock
            Aws::S3::Client.stubs(:new).once.with(region: 'test').returns(mock_client)

            test_client = S3Client.new

            expect(test_client.instance_variable_get(:@s3)).to eq(mock_client)
        end
    end

    describe :store_data do
        before(:each) do
            Aws::S3::Client.stubs(:new).once.with(region: 'test').returns(mock)
            @test_client = S3Client.new

            File.stubs(:read).returns('test_data')
        end

        it 'should successfully call put_object and store the file' do
            @test_client.instance_variable_get(:@s3).stubs(:put_object).once.with(
                body => 'test_data', bucket => 'test_bucket', key => 'test_file'
            )

            @test_client.store_data 'test_file'
        end

        it 'should raise an error if unable to store the file in s3' do
            @test_client.instance_variable_get(:@s3).stubs(:put_object).once.with(
                body => 'test_data', bucket => 'test_bucket', key => 'test_file'
            ).raises(StandardError.new('Unable to store sqlite db in s3'))

            expect {
                @test_client.send(:store_data, 'test_file')
            }.to raise_error(S3Error, 'Unable to store sqlite db in s3')
        end
    end
end
