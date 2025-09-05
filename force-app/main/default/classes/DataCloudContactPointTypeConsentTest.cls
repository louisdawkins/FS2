@isTest
private class DataCloudContactPointTypeConsentTest {
    @isTest
    static void testUpsertConsentRecordNew() {
        // Create test data
        RecordType personAccountRt = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'PersonAccount'];
        Account testAccount = new Account(LastName = 'Test Person', RecordTypeId = personAccountRt.Id);
        insert testAccount;

        Test.startTest();
        // Prepare test request
        List<DataCloudContactPointTypeConsent.Request> testRequests = new List<DataCloudContactPointTypeConsent.Request>();
        DataCloudContactPointTypeConsent.Request testRequest = new DataCloudContactPointTypeConsent.Request();
        testRequest.email_consent = 'TRUE';
        testRequest.phone_consent = 'FALSE';
        testRequest.post_consent = 'TRUE';
        testRequest.sms_consent = 'FALSE';
        testRequest.whatsapp_consent = 'TRUE';
        testRequest.personaccount_id = testAccount.Id;
        testRequests.add(testRequest);

        // Call the method to be tested
        DataCloudContactPointTypeConsent.upsertConsentRecord(testRequests);
        Test.stopTest();

        // Retrieve and verify the consent records
        List<ContactPointTypeConsent> consents = [SELECT Id, PrivacyConsentStatus, Channel__c FROM ContactPointTypeConsent WHERE Person_Account__c = :testAccount.Id];
        Assert.areEqual(5, consents.size());

        for (ContactPointTypeConsent consent : consents) {
            if (consent.Channel__c == 'Email') {
                Assert.areEqual('OptIn', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Phone') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Post') {
                Assert.areEqual('OptIn', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'SMS') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Whatsapp') {
                Assert.areEqual('OptIn', consent.PrivacyConsentStatus);
            }
        }
    }
    
    @isTest
    static void testUpsertConsentRecordExisting() {
        // Create test data
        RecordType personAccountRt = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'PersonAccount'];
        Account testAccount = new Account(LastName = 'Test Person', RecordTypeId = personAccountRt.Id);
        insert testAccount;
        
        Contact indv = [SELECT Id, IndividualId, AccountId FROM Contact WHERE AccountId = :testAccount.Id];
        
        List<ContactPointTypeConsent> consents = new List<ContactPointTypeConsent>();        
        ContactPointTypeConsent consentEmailRecord = new ContactPointTypeConsent();
       	consentEmailRecord.Name = 'Email - Marketing';
        consentEmailRecord.Channel__c = 'Email';
        consentEmailRecord.Legal_Basis__c = 'Consent';
        consentEmailRecord.Person_Account__c = testAccount.Id;
        consentEmailRecord.PartyId = indv.IndividualId;
        consentEmailRecord.PrivacyConsentStatus = 'OptIn'; 
        consents.add(consentEmailRecord);        
        
        ContactPointTypeConsent consentPhoneRecord = new ContactPointTypeConsent();
       	consentPhoneRecord.Name = 'Phone - Marketing';
        consentPhoneRecord.Channel__c = 'Phone';
        consentPhoneRecord.Legal_Basis__c = 'Consent';
        consentPhoneRecord.Person_Account__c = testAccount.Id;
        consentPhoneRecord.PartyId = indv.IndividualId;
        consentPhoneRecord.PrivacyConsentStatus = 'OptIn'; 
        consents.add(consentPhoneRecord);       
        
        ContactPointTypeConsent consentPostRecord = new ContactPointTypeConsent();
       	consentPostRecord.Name = 'Post - Marketing';
        consentPostRecord.Channel__c = 'Post';
        consentPostRecord.Legal_Basis__c = 'Consent';
        consentPostRecord.Person_Account__c = testAccount.Id;
        consentPostRecord.PartyId = indv.IndividualId;
        consentPostRecord.PrivacyConsentStatus = 'OptIn'; 
        consents.add(consentPostRecord);
        
        ContactPointTypeConsent consentSMSRecord = new ContactPointTypeConsent();
       	consentSMSRecord.Name = 'SMS - Marketing';
        consentSMSRecord.Channel__c = 'SMS';
        consentSMSRecord.Legal_Basis__c = 'Consent';
        consentSMSRecord.Person_Account__c = testAccount.Id;
        consentSMSRecord.PartyId = indv.IndividualId;
        consentSMSRecord.PrivacyConsentStatus = 'OptIn'; 
        consents.add(consentSMSRecord);
        
        ContactPointTypeConsent consentWhatsappRecord = new ContactPointTypeConsent();
       	consentWhatsappRecord.Name = 'WhatsApp - Marketing';
        consentWhatsappRecord.Channel__c = 'WhatsApp';
        consentWhatsappRecord.Legal_Basis__c = 'Consent';
        consentWhatsappRecord.Person_Account__c = testAccount.Id;
        consentWhatsappRecord.PartyId = indv.IndividualId;
        consentWhatsappRecord.PrivacyConsentStatus = 'OptIn'; 
        consents.add(consentWhatsappRecord);
        
        insert consents;
        
        Test.startTest();
        // Prepare test request
        List<DataCloudContactPointTypeConsent.Request> testRequests = new List<DataCloudContactPointTypeConsent.Request>();
        DataCloudContactPointTypeConsent.Request testRequest = new DataCloudContactPointTypeConsent.Request();
        testRequest.email_consent = 'FALSE';
        testRequest.phone_consent = 'FALSE';
        testRequest.post_consent = 'FALSE';
        testRequest.sms_consent = 'FALSE';
        testRequest.whatsapp_consent = 'FALSE';
        testRequest.personaccount_id = testAccount.Id;
        testRequests.add(testRequest);

        // Call the method to be tested
        DataCloudContactPointTypeConsent.upsertConsentRecord(testRequests);
        Test.stopTest();
        
        // Retrieve and verify the consent records
        List<ContactPointTypeConsent> updatedConsents = [SELECT Id, PrivacyConsentStatus, Channel__c FROM ContactPointTypeConsent WHERE Person_Account__c = :testAccount.Id];

        for (ContactPointTypeConsent consent : updatedConsents) {
            if (consent.Channel__c == 'Email') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Phone') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Post') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'SMS') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            } else if (consent.Channel__c == 'Whatsapp') {
                Assert.areEqual('OptOut', consent.PrivacyConsentStatus);
            }
        }        
    }
    
    @isTest
    static void testUpsertMassParticipation() {
        // Create test data
        RecordType personAccountRt = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'PersonAccount'];
        Account testAccount = new Account(LastName = 'Test Person', RecordTypeId = personAccountRt.Id);
        insert testAccount;

        Test.startTest();
        // Prepare test request
        List<DataCloudContactPointTypeConsent.Request> testRequests = new List<DataCloudContactPointTypeConsent.Request>();
        DataCloudContactPointTypeConsent.Request testRequest = new DataCloudContactPointTypeConsent.Request();
        testRequest.email_consent = 'TRUE';
        testRequest.personaccount_id = testAccount.Id;
        testRequest.data_source = 'Social Sync Registration';
        testRequests.add(testRequest);

        // Call the method to be tested
        DataCloudContactPointTypeConsent.upsertConsentRecord(testRequests);
        Test.stopTest();

        // Retrieve and verify the consent records
        List<ContactPointTypeConsent> consents = [SELECT Id, PrivacyConsentStatus, Channel__c FROM ContactPointTypeConsent WHERE Person_Account__c = :testAccount.Id];
        Assert.areEqual(2, consents.size());

        for (ContactPointTypeConsent consent : consents) {
            if (consent.Channel__c == 'Email') {
                Assert.areEqual('OptIn', consent.PrivacyConsentStatus);
            }
        }
    }
}