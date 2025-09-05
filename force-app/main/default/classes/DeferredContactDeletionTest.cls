@isTest
public class DeferredContactDeletionTest {
    @testSetup
    static void setupTestData() {
        // Create test accounts and contacts
        Id businessRecordTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, RecordTypeId = businessRecordTypeId));
        }
        insert testAccounts;

        List<Contact> testContacts = new List<Contact>();
        for (Account acc : testAccounts) {
            for (Integer j = 0; j < 2; j++) {
                testContacts.add(new Contact(LastName = 'Test Contact ' + j, AccountId = acc.Id));
            }
        }
        insert testContacts;
    }

    @isTest
    static void testInvokeFutureDeleteMethod() {
        // Fetch test contacts
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 10];
        List<Id> contactIds = new List<Id>();
        for (Contact con : contacts) {
            contactIds.add(con.Id);
        }

        // Call the invocable method
        Test.startTest();
        DeferredContactDeletion.invokeFutureDeleteMethod(contactIds);
        Test.stopTest();

    }

    @isTest
    static void testInvokeFutureDeleteMethodWithEmptyList() {
        // Call the invocable method with an empty list
        List<Id> emptyList = new List<Id>();

        Test.startTest();
        DeferredContactDeletion.invokeFutureDeleteMethod(emptyList);
        Test.stopTest();

    }
}