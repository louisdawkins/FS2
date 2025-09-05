@IsTest
private class DataCloudBulkIngestionCtrlTest {
    @IsTest
    static void testGetConnectorList() {
        List<Data_Cloud_Config__mdt> ingestionApiList = DataCloudBulkIngestionCtrl.getConnectorList();
        
        Assert.isTrue(!ingestionApiList.isEmpty(), 'No connectors listed in Data Cloud Config custom metadata type');        
    }
    
    @IsTest
    static void testGetJwtValues() {
        Map<String, String> jwtAuthMap = new Map<String, String>();
        
        List<Data_Cloud_Config__mdt> dcConfigList = [SELECT Label, DeveloperName, JWT_Value__c FROM Data_Cloud_Config__mdt WHERE DeveloperName LIKE 'JWT%'];
        for (Data_Cloud_Config__mdt jwtValue : dcConfigList) {
            jwtAuthMap.put(jwtValue.DeveloperName, jwtValue.JWT_Value__c);
        }
        
        Assert.isTrue(jwtAuthMap.get('JWT_Subject') != null, 'No JWT Subject set');
        Assert.isTrue(jwtAuthMap.get('JWT_Audience') != null, 'No JWT Audience set');
        Assert.isTrue(jwtAuthMap.get('JWT_Issuer') != null, 'No JWT Issuer set');        
    }
    
    @IsTest
    static void testFullProcessSuccess(){
        String encodedData = 'ZmFjZWJvb2tfaWQKMTk2NDE5Njg=';
        String objectName = 'test_object';
        String sourceName = 'test_source';
        
        // Authorisation
        String authUrl1 = 'https://login.salesforce.com/services/oauth2/token';
        String authUrl2 = 'https://fareshare2.my.salesforce.com/services/a360/token';
        
        // Create, upload, close jobs
        String createUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs';
        String uploadUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418/batches';
        String closeUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418';
        
        // Mock callout
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(authUrl1, 'Mock_DataCloud_SFAuthenticateResponse');        
        multimock.setStaticResource(authUrl2, 'Mock_DataCloud_DCAuthenticateResponse');
        multimock.setStaticResource(createUrl1, 'Mock_DataCloud_CreateJobResponse'); 
        multimock.setStaticResource(uploadUrl1, 'Mock_DataCloud_UploadJobResponse'); 
        multimock.setStaticResource(closeUrl1, 'Mock_DataCloud_CloseJobResponse'); 
        multimock.setStatusCode(200);
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        Test.startTest();
        DataCloudBulkIngestionCtrl.JobStatusWrapper resultWrapper = DataCloudBulkIngestionCtrl.getCsvData(encodedData, objectName, sourceName);
        Test.stopTest();
        
		Assert.areEqual(true, resultWrapper.success, 'Expecting success but got failure');        
    }
    
    @IsTest
    static void testAuthorisationFailure() {        
        Blob file = EncodingUtil.base64Decode('ZmFjZWJvb2tfaWQKMTk2NDE5Njg=');
        String objectName = 'test_object';
        String sourceName = 'test_source';
        
        // Urls
        String authUrl1 = 'https://login.salesforce.com/services/oauth2/token';
        String authUrl2 = 'https://fareshare2.my.salesforce.com/services/a360/token';
        String createUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs';
        
        // Mock callout
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(authUrl1, 'Mock_DataCloud_SFAuthenticateResponse');        
        multimock.setStaticResource(authUrl2, 'Mock_DataCloud_ErrorJobResponse');
        multimock.setStaticResource(createUrl1, 'Mock_DataCloud_CreateJobResponse'); 
        multimock.setStatusCode(400);
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        DataCloudBulkIngestionCtrl.JobStatusWrapper resultWrapper = DataCloudBulkIngestionCtrl.createJob(file, objectName, sourceName);
        
        Assert.areEqual(false, resultWrapper.success, 'Expecting failure but got success');  
        Assert.areEqual('Authorisation', resultWrapper.errorLocation, 'Error location wrong');      
    }
    
    @IsTest
    static void testCreateJobFailure() {
        Blob file = EncodingUtil.base64Decode('ZmFjZWJvb2tfaWQKMTk2NDE5Njg=');
        String objectName = 'test_object';
        String sourceName = 'test_source';
        
        // Urls
        String authUrl1 = 'https://login.salesforce.com/services/oauth2/token';
        String authUrl2 = 'https://fareshare2.my.salesforce.com/services/a360/token';
        String createUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs';
        
        // Mock callout
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(authUrl1, 'Mock_DataCloud_SFAuthenticateResponse');        
        multimock.setStaticResource(authUrl2, 'Mock_DataCloud_DCAuthenticateResponse');
        multimock.setStaticResource(createUrl1, 'Mock_DataCloud_ErrorJobResponse'); 
        multimock.setStatusCode(400);
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        DataCloudBulkIngestionCtrl.JobStatusWrapper resultWrapper = DataCloudBulkIngestionCtrl.createJob(file, objectName, sourceName);
        
        Assert.areEqual(false, resultWrapper.success, 'Expecting failure but got success');  
        Assert.areEqual('Create job', resultWrapper.errorLocation, 'Error location wrong');      
    }
    
    @IsTest
    static void testUploadJobFailure() {
        Blob file = EncodingUtil.base64Decode('ZmFjZWJvb2tfaWQKMTk2NDE5Njg=');
        String objectName = 'test_object';
        String sourceName = 'test_source';
        
        // Urls
        String authUrl1 = 'https://login.salesforce.com/services/oauth2/token';
        String authUrl2 = 'https://fareshare2.my.salesforce.com/services/a360/token';
        String createUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs';
        String uploadUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418/batches';
        String abortUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418';
        
        // Mock callout
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(authUrl1, 'Mock_DataCloud_SFAuthenticateResponse');        
        multimock.setStaticResource(authUrl2, 'Mock_DataCloud_DCAuthenticateResponse');
        multimock.setStaticResource(createUrl1, 'Mock_DataCloud_CreateJobResponse'); 
        multimock.setStaticResource(uploadUrl1, 'Mock_DataCloud_ErrorJobResponse'); 
        multimock.setStaticResource(abortUrl1, 'Mock_DataCloud_AbortJobResponse'); 
        multimock.setStatusCode(400);
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        DataCloudBulkIngestionCtrl.JobStatusWrapper resultWrapper = DataCloudBulkIngestionCtrl.uploadJob('test-token', 'h748nd83msjdn4.c360a.salesforce.com', 'b49ec-f7719b7-9985-28d7a-96cd9ccd418', file);
        
        Assert.areEqual(false, resultWrapper.success, 'Expecting failure but got success');  
        Assert.areEqual('Upload job', resultWrapper.errorLocation, 'Error location wrong');      
    }
    
    @IsTest
    static void testCloseJobFailure() {
        Blob file = EncodingUtil.base64Decode('ZmFjZWJvb2tfaWQKMTk2NDE5Njg=');
        String objectName = 'test_object';
        String sourceName = 'test_source';
        
        // Urls
        String authUrl1 = 'https://login.salesforce.com/services/oauth2/token';
        String authUrl2 = 'https://fareshare2.my.salesforce.com/services/a360/token';
        String createUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs';
        String uploadUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418/batches';
        String closeUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418';
        String abortUrl1 = 'https://h748nd83msjdn4.c360a.salesforce.com/api/v1/ingest/jobs/b49ec-f7719b7-9985-28d7a-96cd9ccd418';
                
        // Mock callout
        MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(authUrl1, 'Mock_DataCloud_SFAuthenticateResponse');        
        multimock.setStaticResource(authUrl2, 'Mock_DataCloud_DCAuthenticateResponse');
        multimock.setStaticResource(createUrl1, 'Mock_DataCloud_CreateJobResponse'); 
        multimock.setStaticResource(uploadUrl1, 'Mock_DataCloud_UploadJobResponse'); 
        multimock.setStaticResource(closeUrl1, 'Mock_DataCloud_ErrorJobResponse'); 
        multimock.setStaticResource(abortUrl1, 'Mock_DataCloud_AbortJobResponse'); 
        multimock.setStatusCode(400);
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, multimock);
        
        DataCloudBulkIngestionCtrl.JobStatusWrapper resultWrapper = DataCloudBulkIngestionCtrl.closeJob('test-token', 'h748nd83msjdn4.c360a.salesforce.com', 'b49ec-f7719b7-9985-28d7a-96cd9ccd418');
        System.debug(resultWrapper);
        Assert.areEqual(false, resultWrapper.success, 'Expecting failure but got success');   
        Assert.areEqual('Close job', resultWrapper.errorLocation, 'Error location wrong');      
    }
}