package com.clicklogs.Handlers;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import org.apache.commons.lang3.StringUtils;

import com.amazonaws.services.lambda.runtime.LambdaLogger;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonSyntaxException;

import java.text.Format;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import com.clicklogs.model.ClickLogRequest;

import com.amazonaws.services.dynamodbv2.AmazonDynamoDB;
import com.amazonaws.services.dynamodbv2.AmazonDynamoDBClientBuilder;
import com.amazonaws.services.dynamodbv2.datamodeling.DynamoDBMapper;
import com.amazonaws.services.dynamodbv2.document.DynamoDB;
import com.amazonaws.services.dynamodbv2.document.Item;
import com.amazonaws.services.dynamodbv2.document.PutItemOutcome;
import com.amazonaws.services.dynamodbv2.document.spec.PutItemSpec;
import com.amazonaws.services.dynamodbv2.model.ConditionalCheckFailedException;
import com.amazonaws.services.lambda.runtime.events.KinesisAnalyticsInputPreprocessingResponse;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisAnalyticsInputPreprocessingResponse.Record;
import com.amazonaws.services.lambda.runtime.events.KinesisAnalyticsInputPreprocessingResponse.Result;


// Handler value: example.Handler
public class ClickLoggerStreamHandler implements RequestHandler<KinesisFirehoseEvent, KinesisAnalyticsInputPreprocessingResponse>{

  private DynamoDB dynamoDb;
  private String dynamo_table_name = "clickLoggertable";
  private String region = "us-east-1";

  Gson gson = new GsonBuilder().setPrettyPrinting().create();

  @Override
  public KinesisAnalyticsInputPreprocessingResponse handleRequest(final KinesisFirehoseEvent event, final Context context) {
    final LambdaLogger logger = context.getLogger();
    final String success_response = new String("200 OK");
    logger.log("EVENT: " + gson.toJson(event));
    

    String env_table = System.getenv("DB_TABLE");
    if(!StringUtils.isBlank(env_table))
    {
      dynamo_table_name = env_table;
    }

    String env_region = System.getenv("AWS_REGION");//  System.getenv("REGION");
    logger.log("Environment region name - " + env_region);
    if(!StringUtils.isBlank(env_region))
    {
      region = env_region;
    }

    List<Record> records = new ArrayList<>();
    

    event.getRecords().forEach(kinesisRecord -> {
          String clickJson = new String(kinesisRecord.getData().array());
          logger.log("Individual record: " + kinesisRecord.getData());
          Gson gson = new Gson();
          try
          {
              ClickLogRequest clickLogRequest = gson.fromJson(clickJson, ClickLogRequest.class);

              String req = clickLogRequest.getRequestid() + " - " + clickLogRequest.getCallerid() + "  - " + clickLogRequest.getComponent() + " - "
                + clickLogRequest.getType() + " - " + clickLogRequest.getAction() + " - "
                + clickLogRequest.getUser() + " - " + clickLogRequest.getClientip() + " - " + clickLogRequest.getCreatedtime();
  
              Boolean valid_input = true;
              logger.log("Incoming request variables - " + req);
      
                if(clickLogRequest != null){
                
                  logger.log("Validating inputs");
                  if (StringUtils.isBlank(clickLogRequest.getRequestid())) {
                    logger.log("error occurred - requestid missing");
                    valid_input = false;
                  }
                  if (StringUtils.isBlank(clickLogRequest.getContextid())) {
                    logger.log("error occurred - contextid missing");
                    valid_input = false;
                  }
                  if (StringUtils.isBlank(clickLogRequest.getCallerid())) {
                    logger.log("error occurred - caller missing");
                    valid_input = false;
                  }
                  if (StringUtils.isBlank(clickLogRequest.getType())) {
                    logger.log("error occurred - type missing");
                    valid_input = false;
                  }
                  if (StringUtils.isBlank(clickLogRequest.getAction())) {
                    logger.log("error occurred - action missing");
                    valid_input = false;
                  }
                  if (StringUtils.isBlank(clickLogRequest.getComponent())) {
                    logger.log("error occurred - component missing");
                    valid_input = false;
                  }
      
                  String user = "GUEST";
                  if (StringUtils.isBlank(clickLogRequest.getUser())) {
                    logger.log("setting default user");
                    clickLogRequest.setUser(user);
                  }
      
                  String clientip = "APIGWY";
                  if (StringUtils.isBlank(clickLogRequest.getClientip())) {
                    logger.log("setting default clientip");
                    clickLogRequest.setClientip(clientip);
                  }
      
                  String datetime = "";
                  if (StringUtils.isBlank(clickLogRequest.getCreatedtime())) {
                    logger.log("setting default createdtime");
                    Format f = new SimpleDateFormat("mm-dd-yyyy hh:mm:ss");
                    datetime = f.format(new Date());
                    clickLogRequest.setCreatedtime(datetime);
                  }
                  logger.log("Validated inputs");
                }
      
                req = clickLogRequest.getRequestid() + " - " + clickLogRequest.getCallerid() + "  - " + clickLogRequest.getComponent() + " - "
                + clickLogRequest.getType() + " - " + clickLogRequest.getAction() + " - "
                + clickLogRequest.getUser() + " - " + clickLogRequest.getClientip() + " - " + clickLogRequest.getCreatedtime();
      
                logger.log("Modified request variables - " + req);
                logger.log("Valid Input - " + String.valueOf(valid_input));
                System.out.println("Calling updateclicklogs method for the received clicklogrequest");
                if(valid_input){
                  updateClickLogs(clickLogRequest);
                }
                
                Record record = new Record();
                record.setRecordId(kinesisRecord.getRecordId());
                record.setData(kinesisRecord.getData());
                Result result = KinesisAnalyticsInputPreprocessingResponse.Result.Ok;
                record.setResult(result);
                records.add(record);
          }
          catch(JsonSyntaxException jsEx){
            System.out.println(jsEx);
          }
    });
   

    KinesisAnalyticsInputPreprocessingResponse response = new KinesisAnalyticsInputPreprocessingResponse(records);
    logger.log(success_response);
    return response;
  }

  private Boolean updateClickLogs(final ClickLogRequest clickLogRequest) {
    this.initDynamoDbClient();
    updateClickData(clickLogRequest);
    System.out.println("Completed update click logs method");
    return true;
  }

  private PutItemOutcome updateClickData(final ClickLogRequest clickLogRequest) 
      throws ConditionalCheckFailedException {
        return dynamoDb.getTable(dynamo_table_name)
          .putItem(
            new PutItemSpec().withItem(new Item()
              .withString("requestid", clickLogRequest.getRequestid())
              .withString("contextid", clickLogRequest.getContextid())
              .withString("callerid", clickLogRequest.getCallerid())
              .withString("type", clickLogRequest.getType())
              .withString("component", clickLogRequest.getComponent())
              .withString("action", clickLogRequest.getAction())
              .withString("createdtime", clickLogRequest.getCreatedtime())
              .withString("clientip", clickLogRequest.getClientip())
              .withString("user", clickLogRequest.getUser())));
    }

  private void initDynamoDbClient() {
      System.out.println("Inside DynamoDBClient method");
      try {
        AmazonDynamoDB client = AmazonDynamoDBClientBuilder.standard().withRegion(region).build();
        this.dynamoDb = new DynamoDB(client);
        System.out.println("set DynamoDBClient method");
      } catch (Exception e) {
        System.out.println("Error occurred - " + e.getMessage());
      }     
    }
}