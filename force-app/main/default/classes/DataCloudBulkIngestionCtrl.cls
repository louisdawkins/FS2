public with sharing class DataCloudBulkIngestionCtrl {
    
    // Represents response from authentication calls
    private class AuthenticateResponse {
        String access_token;
        String instance_url;
        String error;
        String error_description;
    }
    
    // Represents response from Create Job
    private class CreateJobResponse {
        String id;
        String state;
        String error;
        String message;
        String internalErrorCode;
    }
    
    // Represents response from Upload Job
    private class UploadJobResponse {
        String accepted;
        String error;
        String message;
        String internalErrorCode;
    }

    // Represents response from Close Job
    private class CloseJobResponse {
        String state;
        String error;
        String message;
        String internalErrorCode;
    }
    
    // Represents response to LWC
    public class JobStatusWrapper {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String error;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String errorLocation;
    }
    
    // Get Connector list to display on LWC
    @AuraEnabled(cacheable=true)
    public static List<Data_Cloud_Config__mdt> getConnectorList() {
        List<Data_Cloud_Config__mdt> dcConfigList = [SELECT Label, Object_API_Name__c, Source_API_Name__c, Connector__c FROM Data_Cloud_Config__mdt
                                                    WHERE Connector__c = true ORDER BY Label];
        return dcConfigList;
    }
    
    // Get CSV data from LWC upload
    @AuraEnabled 
    public static JobStatusWrapper getCsvData(String encodedCsvData, String objectApiName, String sourceApiName) {
        JobStatusWrapper jobStatus = new JobStatusWrapper();
        System.debug('Running getCsvData');
        
        encodedCsvData = EncodingUtil.urlDecode(encodedCsvData, 'UTF-8');
        System.debug(encodedCsvData);
    	Blob file = EncodingUtil.base64Decode(encodedCsvData);  
        
        jobStatus = createJob(file, objectApiName, sourceApiName);
        
        System.debug(jobStatus);
        return jobStatus;
    }
       
    // Authenticate user against Data Cloud instance and obtain Salesforce access token 
    // and return Data Cloud token and instance url for further jobs
    public static Map<String, String> authenticateUser() {   
        Map<String, String> authenticationMap = new Map<String, String>();
        Map<String, String> jwtAuthMap = new Map<String, String>();
        
        List<Data_Cloud_Config__mdt> dcConfigList = [SELECT Label, DeveloperName, JWT_Value__c FROM Data_Cloud_Config__mdt WHERE DeveloperName LIKE 'JWT%'];
        for (Data_Cloud_Config__mdt jwtValue : dcConfigList) {
            jwtAuthMap.put(jwtValue.DeveloperName, jwtValue.JWT_Value__c);
        }        
        
        Auth.JWT jwt = new Auth.JWT();		
        jwt.setSub(jwtAuthMap.get('JWT_Subject'));
        jwt.setAud(jwtAuthMap.get('JWT_Audience')); 
        jwt.setIss(jwtAuthMap.get('JWT_Issuer'));        
        
        //Create the object that signs the JWT bearer token
        Auth.JWS jws = new Auth.JWS(jwt,'salesforcetest');
        String token = jws.getCompactSerialization();
        String tokenEndpoint = 'https://login.salesforce.com/services/oauth2/token';
        
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(tokenEndpoint, jws);
        String accessToken1;
        if (!Test.isRunningTest()) {                 
            accessToken1 = bearer.getAccessToken();             
        } else {                 
            accessToken1 = 'test-token';             
        }    
        
        // If first authentication successful, proceed with obtaining Data Cloud token
        if (accessToken1 != null) {
            Http h2 = new Http();
            HttpRequest req2 = new HttpRequest();
            req2.setMethod('POST');
            req2.setEndpoint('https://fareshare2.my.salesforce.com/services/a360/token');
            req2.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req2.setBody(
                'grant_type=urn:salesforce:grant-type:external:cdp' + 
                '&subject_token=' + accessToken1 + 
                '&subject_token_type=urn:ietf:params:oauth:token-type:access_token'
            );
            
            // Send request
            HttpResponse response2 = h2.send(req2);   
            System.debug('Authentication 2: ' + response2);
            
            // Get the response 
            AuthenticateResponse authenticateResponseDataCloud = (AuthenticateResponse)JSON.deserialize(response2.getBody(),AuthenticateResponse.class); 
            System.debug(authenticateResponseDataCloud);
            
            String dataCloudToken = authenticateResponseDataCloud.access_token;
            String dataCloudInstanceUrl = authenticateResponseDataCloud.instance_url; 
            
            authenticationMap.put('token', dataCloudToken);
            authenticationMap.put('instance_url', dataCloudInstanceUrl);
        }        
       
        return authenticationMap;
    }
    
    // Bulk Ingestion API - Create Job
    public static JobStatusWrapper createJob(Blob data, String objectApiName, String sourceApiName) {
 		JobStatusWrapper jobStatus = new JobStatusWrapper();
        
        // First must authenticate user, get access token and instance url
        Map<String, String> authenticationIds = authenticateUser();
        String token = authenticationIds.get('token');
        String instanceUrl = authenticationIds.get('instance_url');
        
        if (token != null && instanceUrl != null) {
            System.debug('Running createJob');
            
            Http h1 = new Http();
            HttpRequest req1 = new HttpRequest();
            req1.setMethod('POST');
            req1.setEndpoint('https://' + instanceUrl + '/api/v1/ingest/jobs'); 
            req1.setHeader('Authorization', 'Bearer ' + token);
            req1.setHeader('Content-Type', 'application/json');
            req1.setBody(
                '{"object":"'+objectApiName+'",'+
   				'"sourceName":"'+sourceApiName+'",'+
   				'"operation":"upsert"}'
            );

			// Send request
        	HttpResponse response1 = h1.send(req1);
            System.debug('Create job: ' + response1);
            
            // Get the response 
            CreateJobResponse createResponse = (CreateJobResponse)JSON.deserialize(response1.getBody(),CreateJobResponse.class); 
            System.debug(createResponse);      
            
            // Get the job id
            String jobId = createResponse.id;
            
            // Go to next step
            if (jobId != null) {
                jobStatus = uploadJob(token, instanceUrl, jobId, data); 
            } else {
                jobStatus.success = false;
                jobStatus.error = createResponse.error;
                jobStatus.errorMessage = createResponse.message;
                jobStatus.errorLocation = 'Create job';                
            }            
        } else {
                jobStatus.success = false;
                jobStatus.errorLocation = 'Authorisation';   
        }
        
        return jobStatus;
    }
           
    // Bulk Ingestion API - Upload Job
    public static JobStatusWrapper uploadJob(String token, String instanceUrl, String jobId, Blob data) {
        JobStatusWrapper jobStatus = new JobStatusWrapper();
        System.debug('Running uploadJob');
        
        Http h1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('PUT');
        req1.setEndpoint('https://' + instanceUrl + '/api/v1/ingest/jobs/' + jobId + '/batches'); 
        req1.setHeader('Authorization', 'Bearer ' + token);
        req1.setHeader('Content-Type', 'text/csv');
        req1.setBodyAsBlob(
            data
        );

        // Send request
        HttpResponse response1 = h1.send(req1);
        System.debug('Upload job: ' + response1);   
    
        // Get the response 
        UploadJobResponse uploadResponse = (UploadJobResponse)JSON.deserialize(response1.getBody(),UploadJobResponse.class); 
        System.debug(uploadResponse);    
        
        // Go to next step 
        if (uploadResponse.accepted == 'true') {
            jobStatus = closeJob(token, instanceUrl, jobId);            
        } else {
            abortJob(token, instanceUrl, jobId);
            jobStatus.success = false;
            jobStatus.error = uploadResponse.error;
            jobStatus.errorMessage = uploadResponse.message;
            jobStatus.errorLocation = 'Upload job';
        }
        
        return jobStatus;
    }
    
    // Bulk Ingestion API - Close Job
    public static JobStatusWrapper closeJob(String token, String instanceUrl, String jobId) {
        JobStatusWrapper jobStatus = new JobStatusWrapper();
        System.debug('Running closeJob');
        
        Http h1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('PATCH');
        req1.setEndpoint('https://' + instanceUrl + '/api/v1/ingest/jobs/' + jobId); 
        req1.setHeader('Authorization', 'Bearer ' + token);
        req1.setHeader('Content-Type', 'application/json');
        req1.setBody(
            '{"state" : "UploadComplete"}'
        );

        // Send request
        HttpResponse response1 = h1.send(req1);
        System.debug('Close job: ' + response1);    
        
        // Get the response 
        CloseJobResponse closeResponse = (CloseJobResponse)JSON.deserialize(response1.getBody(),CloseJobResponse.class); 
        System.debug(closeResponse);   
        
        if(closeResponse.state != 'UploadComplete') {
            abortJob(token, instanceUrl, jobId);
            jobStatus.success = false;
            jobStatus.error = closeResponse.error;
            jobStatus.errorMessage = closeResponse.message;
            jobStatus.errorLocation = 'Close job';
        } else {
            jobStatus.success = true;
        }
        
        return jobStatus;
    }
    
    // Bulk Ingestion API - Abort Job
    public static void abortJob(String token, String instanceUrl, String jobId) {
        JobStatusWrapper jobStatus = new JobStatusWrapper();
        System.debug('Running abortJob');
        
        Http h1 = new Http();
        HttpRequest req1 = new HttpRequest();
        req1.setMethod('PATCH');
        req1.setEndpoint('https://' + instanceUrl + '/api/v1/ingest/jobs/' + jobId); 
        req1.setHeader('Authorization', 'Bearer ' + token);
        req1.setHeader('Content-Type', 'application/json');
        req1.setBody(
            '{"state" : "Aborted"}'
        );

        // Send request
        HttpResponse response1 = h1.send(req1);
        System.debug('Abort job: ' + response1);    
        
        // Get the response 
        CloseJobResponse closeResponse = (CloseJobResponse)JSON.deserialize(response1.getBody(),CloseJobResponse.class); 
        System.debug(closeResponse);          
    }   
}