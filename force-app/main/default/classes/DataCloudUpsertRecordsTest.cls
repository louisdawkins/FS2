@isTest
private class DataCloudUpsertRecordsTest {
    @isTest 
    static void testUpsertRecord() {
        // Create test Person Accounts
        Id personAccountRtId = [SELECT Id FROM RecordType WHERE DeveloperName='PersonAccount' AND SObjectType='Account'].Id;
        Account testContact1 = new Account(LastName = 'Test1', PersonEmail = 'test1@example.com', RecordTypeId = personAccountRtId);
        Account testContact2 = new Account(LastName = 'Test2', PersonEmail = 'test2@example.com', RecordTypeId = personAccountRtId);
        insert new List<Account>{testContact1, testContact2};

        // Fetch their Contact Ids       
        List<Contact> paContacts = [SELECT Id FROM Contact WHERE AccountId =: testContact1.Id OR AccountId =: testContact2.Id];

        // Create PartyRoleRelations
        PartyRoleRelation partyRole = new PartyRoleRelation(Name = 'Organiser-Participant-CCR', RoleName = 'Organiser', RelatedRoleName = 'Participant', 
                                                            RelationshipObjectName = 'Contact_Contact_Relationship');
        insert partyRole;
        
        PartyRoleRelation partyRoleInverse = new PartyRoleRelation(Name = 'Participant-Organiser-CCR', RoleName = 'Participant', RelatedRoleName = 'Organiser', RelatedInverseRecordId = partyRole.Id,
                                                                  RelationshipObjectName = 'Contact_Contact_Relationship');
        insert partyRoleInverse;        
            
        // Create test CCR
        ContactContactRelation ccrRecord = new ContactContactRelation();
        ccrRecord.ContactId = paContacts[0].Id;
        ccrRecord.RelatedContactId = paContacts[1].Id;
        ccrRecord.IsActive = true;
        ccrRecord.PartyRoleRelationId = partyRoleInverse.Id;
        
        // Prepare the request list
        List<DataCloudUpsertRecords.Request> requestList = new List<DataCloudUpsertRecords.Request>();
        DataCloudUpsertRecords.Request contactRequest = new DataCloudUpsertRecords.Request();
        contactRequest.record = ccrRecord;
        requestList.add(contactRequest);
        
        // Call the method to test
        Test.startTest();
        DataCloudUpsertRecords.upsertRecord(requestList);
        Test.stopTest();
        
        // Query the database to verify the upsert
        List<ContactContactRelation> queriedCcrs = [SELECT Id, PartyRoleRelationId, PartyRoleRelation.Name, PartyRoleRelation.RoleName FROM ContactContactRelation];
        
        // Assert that the records have been upserted
        Assert.areEqual(2, queriedCcrs.size(), 'One CCR and its inverse should have been upserted');
    }
}