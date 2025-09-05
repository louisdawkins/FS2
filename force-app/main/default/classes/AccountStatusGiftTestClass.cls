@IsTest 
    public class AccountStatusGiftTestClass{
    
    @TestSetup
        static void makeData() {
        
            Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
            
            Account accBefore = New Account(
               FirstName='James',
               LastName='Test Person', 
               Status__c='Existing',
               RecordTypeId=personAccountRecordTypeId
            );
            System.debug('Status Before Gift: ' + accBefore.Status__c + ' ,Last Name ' + accBefore.LastName + ' Person Account  ' + accBefore.IsPersonAccount + ' Record Type ' + accBefore.RecordTypeId);
            
            // Insert Account
            insert accBefore; 
            
            Account acc = [SELECT Id, PersonContactId FROM Account WHERE Id = :accBefore.Id];        
            Contact con = [SELECT Id, Name FROM Contact WHERE AccountId = :accBefore.Id];
            System.debug('Contact: ' + con);
            System.debug('Account: ' + accBefore.Id);   
            System.debug('PersonContactId: ' + acc.PersonContactId);    
            
            
            Finance_Codes__c finBefore = New Finance_Codes__c(
               Name='James Finance',
               PCode__c='666'
            );
            
            insert finBefore;
            
        //    cpm__GT_Installment_Field_Mapping__c CS = new cpm__GT_Installment_Field_Mapping__c (
         //   fdff__Gift_Transaction_Field__C ='DonorID', 
          //  fdff__Installment_Field__C='cpm__Account__C'
          //  );
            
        //    insert CS;
        
        Killswitch__c killSwitchSetting = new Killswitch__C(
        Val_Instalment__c = true
        );
        insert killSwitchSetting;
            
            
            Id GiftRecordTypeID = Schema.SObjectType.GiftTransaction.getRecordTypeInfosByDeveloperName().get('Receivable').getRecordTypeId();
               
            GiftTransaction gift = new GiftTransaction(
               Name='James Transaction', 
               Status='Paid',
               Finance_Code__c=finBefore.Id, 
               OriginalAmount=5000, 
               TransactionDate=Date.today(),
               DonorId=accBefore.Id, 
               PaymentMethod='PayPal', 
               GiftType='Individual',
               RecordTypeId=GiftRecordTypeID,
               Exclude_from_Findock_Gift_Aid_Processing__c=True
            );
            
            System.debug('Gift Transaction: ' + gift);
            
            // Insert Gift Transaction        
            insert gift;
             
            //   cpm__Installment__c install = new cpm__Installment__c(
            //  cpm__Account__c=accBefore.Id,
            //  cpm__Contact__c=accBefore.PersonContactId,
            //  fdff__GiftTransaction__c=gift.Id
            //     );
            
            //    System.debug('Donor: ' + install.cpm__Account__c);
            
            //insert install;
            
    }
    
        @IsTest
    
            static void validateAccountStatusBasedOnGiftTransaction() { 
            Test.startTest();
            
            AccountStatusBasedOnGiftTransaction batch = new AccountStatusBasedOnGiftTransaction();
            DataBase.executeBatch(batch);
            
            Test.stopTest();
            
            // Retrieve Donor
            
            Account accAfter = [SELECT Status__c FROM Account LIMIT 1];
            System.debug('Status Of Account: ' + accAfter.Status__c);
            
            // Test that the trigger correctly updated the status
            Assert.areEqual('New', accAfter.Status__c,'Account Status should be set to New.');
        }
    }