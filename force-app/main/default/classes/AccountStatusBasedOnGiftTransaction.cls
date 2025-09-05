public class AccountStatusBasedOnGiftTransaction Implements Database.Batchable<SObject>{

    public Map<Account, GiftTransaction> accountToGiftTransactionMap = new Map<Account, GiftTransaction>();

        public List<Account> accountsToUpdate = new List<Account>();
    
            public Database.QueryLocator start(Database.BatchableContext bc ){
        return Database.getQueryLocator([SELECT
            Id,(SELECT DonorId, TransactionDate
                FROM GiftTransactions
                WHERE Status = 'Paid'
                ORDER BY TransactionDate DESC
                LIMIT 1)
        FROM Account
     //   WHERE Id IN (SELECT DonorId FROM GiftTransaction)
        WHERE Status__c != 'Lapsed'
        ]);
    }
    
public void execute(Database.BatchableContext context, List<Account> scope){
    for (Account acc : scope){
    if (acc.GiftTransactions.size () > 0) {
       accountToGiftTransactionMap.put(acc, acc.GiftTransactions[0]);
       }
    }
    
    for (Account acc : accountToGiftTransactionMap.keySet()) {
        GiftTransaction gt = accountToGiftTransactionMap.get(acc);
        acc.Status__c = determineStatusFromTransactionDate(gt.TransactionDate);
        if (acc.Status__c != null) {
            accountsToUpdate.add(acc);
        }
    }
    // if you want to debug the results before updating
    for (Account acc : accountsToUpdate) {
        System.debug('Id: ' + acc.Id + ', Status: ' + acc.Status__c);
    }
    update accountsToUpdate;
    }
   public static String determineStatusFromTransactionDate(Date transactionDate) {
    if (transactionDate == null) {
        return null;
    }
    Date today = Date.today();
    Integer monthsDifference = Math.abs(today.monthsBetween(transactionDate));
    if (monthsDifference <= 12) {
        return 'New';
    } else if (monthsDifference <= 24) {
        return 'Existing';
    } else {
        return 'Lapsed';
    }
}
    

    public void finish(Database.BatchableContext context) {
    }
}