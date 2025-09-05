public with sharing class DeferredContactDeletion {
    @InvocableMethod(label='Delete Contacts' description='Delete Contacts')
    public static void invokeFutureDeleteMethod(List<Id> recordIds) {
        if(!recordIds.isEmpty()){
            deleteRecords(recordIds);      
        }
    }
    
    @future
    public static void deleteRecords(List<Id> contactIdList) {
        try {
            Database.delete(contactIdList);
        } catch (DmlException e) {
            // Handle exception
            System.debug('DML Exception: ' + e.getMessage());
        }
    }
}