package com.clicklogs;

import static org.mockito.Mockito.when;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.events.KinesisAnalyticsInputPreprocessingResponse;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent;
import com.amazonaws.services.lambda.runtime.events.KinesisFirehoseEvent.Record;
//import com.amazonaws.services.lambda.runtime.events.KinesisAnalyticsInputPreprocessingResponse.Record;
import com.clicklogs.Handlers.ClickLoggerStreamHandler;
import com.clicklogs.model.ClickLogRequest;
import com.google.gson.Gson;

import org.junit.Before;
import org.junit.Test;
import org.mockito.Mockito;

import org.junit.Assert;

public class ClickLoggerStreamHanderTest {
    Gson gson = new Gson();
    KinesisFirehoseEvent event = new KinesisFirehoseEvent();
    ClickLogRequest clickLogRequest = new ClickLogRequest();

    Context context =  Mockito.mock(Context.class);
    ClickLoggerStreamHandler clickLoggerSreamHandler = Mockito.mock(ClickLoggerStreamHandler.class);

  @Before
  public void setup() {
    List<Record> records = new ArrayList<>();

    Record record = new Record();
    clickLogRequest = new ClickLogRequest();
    clickLogRequest.setAction("ACTION");
    clickLogRequest.setCallerid("CALLERID");
    clickLogRequest.setClientip("CLIENTIP");
    clickLogRequest.setComponent("COMPONENT");
    clickLogRequest.setContextid("CONTEXTID");
    clickLogRequest.setCreatedtime("CREATEDTIME");
    clickLogRequest.setRequestid("REQUESTID");
    clickLogRequest.setType("TYPE");
    clickLogRequest.setUser("USER");

    when(clickLogRequest).thenReturn(this.clickLogRequest);
    record = new Record();
    record.setData(ByteBuffer.wrap(clickLogRequest.toString().getBytes()));
    records.add(record);
    event.setRecords(records);
    when(event).thenReturn(this.event);

  
  }

  @Test
  void invokeTest() {
        KinesisAnalyticsInputPreprocessingResponse response = new KinesisAnalyticsInputPreprocessingResponse();
        response = clickLoggerSreamHandler.handleRequest(event, context);
        Assert.assertNotNull(response);
        // Assert.assertEquals(response.getRecords()., 1);
    
  }
}