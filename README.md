# Ingesting Web Application Click Logs into AWS using Terraform (By HashiCorp)

This post provides an API based ingestion application system for websites & applications to push user interactions, click actions from their website into AWS. The ingestion process will be exposed using a web-based interaction with an API Gateway endpoint. 

The Amazon API Gateway (https://aws.amazon.com/api-gateway/) processes the incoming data into an AWS Lambda (https://aws.amazon.com/lambda/) during which the system validates the request using a Lambda Authorizer and pushes the data to a Amazon Kinesis Data Firehose (https://aws.amazon.com/kinesis/data-firehose/). Leverage Firehose’s capability to convert the incoming data and convert it into a Parquet file before pushing it to Amazon S3 (https://aws.amazon.com/s3/). AWS Glue catalog (https://aws.amazon.com/glue/) is used for the conversion. Additionally, a transformational/consumer lambda does additional processing by pushing it to Amazon DynamoDB (https://aws.amazon.com/dynamodb/). 

The data hosted in Amazon S3 (Parquet file) and DynamoDB can be eventually used for generating reports and metrics depending on customer needs to monitor user experience, behavior and additionally provide better recommendations on their website.

The following steps provide an overview of this implementation:

1. Java source build – Provided code is packaged & build using Apache Maven (https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html)

2. Terraform commands are initiated (provided below) to deploy the infrastructure in AWS. 
3. An API Gateway, S3 bucket, Dynamo table, following Lambdas are built and deployed in AWS.
   a. Lambda Authorizer – This lambda validates the incoming request for header authorization from API gateway to processing lambda. 
        * ClickLogger Lamba – This lambda processes the incoming request and pushes the data into Firehose stream
        * Transformational Lambda – This lambda listens to the Firehose stream data and processes this to DynamoDB. In real world these lambda can more additional filtering, processing etc.,
   b. Once the data “POST” is performed to the API Gateway exposed endpoint, the data traverses through the lambda and Firehose stream converts the incoming stream into a Parquet file. We use AWS Glue to perform this operation.
   c. The incoming click logs are eventually saved as Parquet files in S3 bucket and additionally in the DynamoDB

![Alt text](ingesting%20click%20logs%20from%20web%20application.png?raw=true "Title")

### Prerequisites

    - Make sure to have Java installed and running on your machine. For instructions, see Java Development Kit (https://www.oracle.com/java/technologies/javase-downloads.html)
    - Set up Terraform. For steps, see Terraform downloads (https://www.terraform.io/downloads.html).

### Steps

1. Clone this repository and execute the below command to spin up the infrastructure and the application

2. Execute the below commands

    ```
    $ cd aws-ingesting-click-logs-using-terraform
    $ cd source\clicklogger
    $ mvn clean package
    $ cd ..
    $ cd ..
    $ cd terraform\templates
    $ terraform init
    $ terraform plan
    $ terraform apply –auto-approve
    ```

### Test

1. In AWS Console, select “API Gateway”. Select “click-logger-api” 
2. Select “Stages” on the left pane
3. Click “dev” > “POST” (within the “/clicklogger” route)
4. Copy the invoke Url. A sample url will be like this -  https://qvu8vlu0u4.execute-api.us-east-1.amazonaws.com/dev/clicklogger
5. Use REST API tool like Postman or Chrome based web extension like RestMan to post data to your endpoint

    Add Header: Key “Authorization” with value “ALLOW=ORDERAPP”.

    Sample Json Request:
    ```
    {
        "requestid": "OAP-guid-05122020-1345-12345-678910",
        "contextid": "OAP-guid-05122020-1345-1234-5678",
        "callerid": "OrderingApplication",
        "component": "login",
        "action": "click",
        "type": "webpage"
    }
    ```
6. Output - You should see the output in both S3 bucket and DynamoDB
    a. S3 – Navigate to the bucket created as part of the stack
        * Select the file and view the file from “Select From” sub tab . You should see something ingested stream got converted into parquet file.
        * Select the file and view the data
    b. DynamoDB table - Select “clickloggertable” and view the “items” to see data. 
 
 ## Cleanup

**Make sure to check the following are deleted before the delete stacks are performed**

   - Contents of the S3 files are deleted
        - Go to "Resources" tab, select the s3 bucket created as part of the  stack and delete the S3 bucket manually.
        - Select all the contents & delete the contents manually


**S3 and created services can be deleted using CLI also. Execute the below commands:**

    ```
    # CLI Commands to delete the S3  
    $ aws s3 rb s3://click-logger-firehose-delivery-bucket-<your-account-number> --force
    $ terraform destroy –-auto-approve
    ```


## References

* Terraform:  Beyond the basics with AWS 
https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/

* API Management strategies 
https://aws.amazon.com/api-gateway/api-management/

* Amazon Kinesis
https://aws.amazon.com/kinesis/

* API Gateway with Lambda Authorizers
https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-control-access-to-api.html

* Kinesis Data Streams (KDS)
https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-control-access-to-api.html






## License

This library is licensed under the MIT-0 License. See the LICENSE file.
