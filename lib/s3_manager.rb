require 'aws-sdk-s3'


# Class for managing the state of the poller in S3
class S3Client
    # Create S3 client
    def initialize
       @s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    end

    def store_data file
        $logger.info "Storing #{file} in s3 for retrieval by check-in card API"

        # Read file into memory
        sqlData = File.read("/tmp/#{file}")

        # Store file in s3
        begin
            resp = @s3.put_object({
                :body => sqlData,
                :bucket => "check-in-card-data",
                :key => file,
            })
        rescue Exception => e
            $logger.error "Unable to store sqlite db in s3", { :status => e.message } 
            raise S3Error "Unable to store sqlite db in s3"
        end
    end
end


class S3Error < StandardError; end