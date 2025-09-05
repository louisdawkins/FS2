global class AccountStatusBasedScheduler Implements Schedulable 
{
         global void execute(SchedulableContext sc)
    {
        AccountStatusBasedOnGiftTransaction batch= new AccountStatusBasedOnGiftTransaction  ();
        Database.executebatch(batch,25);
    }
    }