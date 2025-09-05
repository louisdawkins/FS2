/**
 * @description Used to upsert records created via Data Cloud process 
 *
 * @author Solution Junkies
 *
 * @date 2024
 */
public without sharing class DataCloudUpsertRecords {
    /**
     * @description Upserts records when platform event triggered flow is fired; can be extended for any object
     */
    @InvocableMethod(label='Upsert Data Cloud Records' description='Upserts records')
    public static void upsertRecord(List<Request> requestList) { 
        System.debug(requestList);
        List<SObject> recordsToUpsert = new List<SObject>();
        List<ContactContactRelation> ccrToUpsert = new List<ContactContactRelation>();  
                  
        for (Request req : requestList) { 
            recordsToUpsert.add(req.record);
            System.debug('payload:');
            System.debug(req.payload);
        }        
        
        if (!recordsToUpsert.isEmpty()) {            
            for (SObject record : recordsToUpsert) {
                if (record instanceof ContactContactRelation) {
                    ccrToUpsert.add((ContactContactRelation) record);
                }             
            }            
            System.debug('ccrToUpsert size: ' + ccrToUpsert.size());
                        
            // Insert Contact-Contact Relationships
            if (!ccrToUpsert.isEmpty()) {
                System.debug(ccrToUpsert);
                
                PartyRoleRelation partyRole = [SELECT Id, RoleName, RelatedRoleName, RelatedInverseRecordId FROM PartyRoleRelation 
                                               WHERE RoleName = 'Participant' AND RelatedRoleName = 'Organiser'];
                
                List<ContactContactRelation> inverseCcrToUpsert = new List<ContactContactRelation>();  
                
                // Update Party Role on record & create inverse record
                for (ContactContactRelation ccr : ccrToUpsert) {
                    ccr.PartyRoleRelationId = partyRole.Id;
                    
                    ContactContactRelation inverseCcr = new ContactContactRelation();
                    inverseCcr.ContactId = ccr.RelatedContactId;
                    inverseCcr.RelatedContactId = ccr.ContactId;
                    inverseCcr.IsActive = true;
                    inverseCcr.PartyRoleRelationId = partyRole.RelatedInverseRecordId;
                    inverseCcrToUpsert.add(inverseCcr);
                }
                ccrToUpsert.addAll(inverseCcrToUpsert);
                system.debug('inverseCcrToUpsert=> '+JSON.serialize(inverseCcrToUpsert));
                system.debug('ccrToUpsert=> '+JSON.serialize(ccrToUpsert));
                System.debug(ccrToUpsert.size());
                
                List<Database.SaveResult> results = Database.insert(ccrToUpsert, false); // false = partial success 
                System.debug(results);
            }
        }
    }
        
    public class Request {
        @InvocableVariable
        public SObject record; 
        
        @InvocableVariable
        public String payload;
        
        @InvocableVariable
        public String origin;  
                
        @InvocableVariable
        public String unique_identifier;        
    }
}