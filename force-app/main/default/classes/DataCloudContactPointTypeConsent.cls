/**
 * @description Used to upsert ContactPointTypeConsent records 
 *
 * @author Solution Junkies
 *
 * @date 2024
 */
public class DataCloudContactPointTypeConsent {
    /**
     * @description Upserts ContactPointTypeConsen records when platform event triggered flow is fired
     */
    @InvocableMethod(label='Upsert Consent Records' description='Upserts Consent records')
    public static void upsertConsentRecord(List<Request> requestList) { 
        System.debug(requestList);
        
        String dataSource = requestList[0].data_source;
        List<ContactPointTypeConsent> consentsToUpsert = new List<ContactPointTypeConsent>();
        Map<Id, ContactPointTypeConsent> consentsToUpsertMap = new Map<Id, ContactPointTypeConsent>();
        Map<String, String> accToIndvMap = new Map<String, String>(); 
        List<String> listOfPersonAccIds = new List<String>();
        
        // Collate list of Person Account ids
        for (Request req : requestList) {
            listOfPersonAccIds.add(req.personaccount_id);
        }
        
        // Find Individual ids from Person Account ids
        List<Contact> indvList = [SELECT Id, IndividualId, AccountId FROM Contact WHERE AccountId IN : listOfPersonAccIds];
        for (Contact con : indvList) {
            accToIndvMap.put(con.AccountId, con.IndividualId);
        }
        
        // Get DataUsePurpose id
        String marketingPurposeId = [SELECT Id, Name FROM DataUsePurpose WHERE Name = 'Marketing'].size() == 1 ? [SELECT Id, Name FROM DataUsePurpose WHERE Name = 'Marketing'].Id : null; 
        String emailMassParticipationPurposeId = [SELECT Id, Name FROM DataUsePurpose WHERE Name = 'Mass Event Participation'].size() == 1 ? [SELECT Id, Name FROM DataUsePurpose WHERE Name = 'Mass Event Participation'].Id : null; 
        
        // Get existing consents
        List<ContactPointTypeConsent> existingConsents = [SELECT Id, Person_Account__c, Channel__c, PrivacyConsentStatus, DataUsePurposeId
                                                         FROM ContactPointTypeConsent WHERE Person_Account__c IN : listOfPersonAccIds];
        
        // Consent channel maps
        Map<String, ContactPointTypeConsent> consentEmailMap = new Map<String, ContactPointTypeConsent>();
        Map<String, ContactPointTypeConsent> consentPhoneMap = new Map<String, ContactPointTypeConsent>();
        Map<String, ContactPointTypeConsent> consentPostMap = new Map<String, ContactPointTypeConsent>();
        Map<String, ContactPointTypeConsent> consentSmsMap = new Map<String, ContactPointTypeConsent>();
        Map<String, ContactPointTypeConsent> consentWhatsappMap = new Map<String, ContactPointTypeConsent>();
        Map<String, ContactPointTypeConsent> consentMassParticipationMap = new Map<String, ContactPointTypeConsent>();
        
        for (ContactPointTypeConsent consent : existingConsents) {
            if (consent.Channel__c.toLowerCase() == 'email' && consent.DataUsePurposeId == marketingPurposeId) {
                consentEmailMap.put(consent.Person_Account__c, consent);
            } 
            if (consent.Channel__c.toLowerCase() == 'phone') {
                consentPhoneMap.put(consent.Person_Account__c, consent);
            }
            if (consent.Channel__c.toLowerCase() == 'post') {
                consentPostMap.put(consent.Person_Account__c, consent);
            }     
            if (consent.Channel__c.toLowerCase() == 'sms') {
                consentSmsMap.put(consent.Person_Account__c, consent);
            }     
            if (consent.Channel__c.toLowerCase() == 'whatsapp') {
                consentWhatsappMap.put(consent.Person_Account__c, consent);
            }   
            if (consent.Channel__c.toLowerCase() == 'email' && consent.DataUsePurposeId == emailMassParticipationPurposeId) {
                consentMassParticipationMap.put(consent.Person_Account__c, consent);
            } 
        }
        
        Map<String, String> consentOptInOutMap = new Map<String, String>();
        consentOptInOutMap.put('TRUE', 'OptIn');
        consentOptInOutMap.put('FALSE', 'OptOut');
        
        Map<String, String> consentStatementMap = new Map<String, String>();
        consentStatementMap.put('Donr', 'DONR1');
        consentStatementMap.put('Social Sync Registration', 'SocialSync1');
        consentStatementMap.put('Social Sync Transaction', 'SocialSync1');
        consentStatementMap.put('UpwardComms', 'UpwardComms1');    
        consentStatementMap.put('Return', 'Return1'); 
        
        Map<String, String> consentCaptureSourceMap = new Map<String, String>();
        consentCaptureSourceMap.put('Donr', 'Donr');
        consentCaptureSourceMap.put('Social Sync Registration', 'Social Sync');
        consentCaptureSourceMap.put('Social Sync Transaction', 'Social Sync');
        consentCaptureSourceMap.put('UpwardComms', 'Upward Comms');    
        consentCaptureSourceMap.put('Return', '	Return Fundraising');         
                
        for (Request req : requestList) {   
            if (req.personaccount_id != null && req.personaccount_id != '') {      
                // Email Consent
                if (req.email_consent != null && req.email_consent != '') {
                    // If Consent record does not exist but Consent preference has come through, create record
                    if (consentEmailMap.get(req.personaccount_id) == null) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'Email - Marketing';
                        consentRecord.Channel__c = 'Email';
                        consentRecord.DataUsePurposeId = marketingPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = req.email_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.email_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord); 
                    }
                    
                    // If Consent record does exist but Consent preference is different, update record            
                    else if (consentEmailMap.get(req.personaccount_id) != null && consentEmailMap.get(req.personaccount_id).PrivacyConsentStatus != consentOptInOutMap.get(req.email_consent)) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Id = consentEmailMap.get(req.personaccount_id).Id;
                        consentRecord.PrivacyConsentStatus = req.email_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.email_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';    
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentsToUpsertMap.put(consentRecord.Id, consentRecord);
                    }                  
                }
             
                // Phone Consent
                if (req.phone_consent != null && req.phone_consent != '') {
                    // If Consent record does not exist but Consent preference has come through, create record
                    if (consentPhoneMap.get(req.personaccount_id) == null) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'Phone - Marketing';
                        consentRecord.Channel__c = 'Phone';
                        consentRecord.DataUsePurposeId = marketingPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = req.phone_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.phone_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord);                 
                    }
                    
                    // If Consent record does exist but Consent preference is different, update record            
                    else if (consentPhoneMap.get(req.personaccount_id) != null && consentPhoneMap.get(req.personaccount_id).PrivacyConsentStatus != consentOptInOutMap.get(req.phone_consent)) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Id = consentPhoneMap.get(req.personaccount_id).Id;
                        consentRecord.PrivacyConsentStatus = req.phone_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.phone_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';  
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentsToUpsertMap.put(consentRecord.Id, consentRecord);
                    }                  
                }
                
                // Post Consent
                if (req.post_consent != null && req.post_consent != '') {
                    // If Consent record does not exist but Consent preference has come through, create record
                    if (consentPostMap.get(req.personaccount_id) == null) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'Post - Marketing';
                        consentRecord.Channel__c = 'Post';
                        consentRecord.DataUsePurposeId = marketingPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = req.post_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.post_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord);     
                    }
                    
                    // If Consent record does exist but Consent preference is different, update record            
                    else if (consentPostMap.get(req.personaccount_id) != null && consentPostMap.get(req.personaccount_id).PrivacyConsentStatus != consentOptInOutMap.get(req.post_consent)) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Id = consentPostMap.get(req.personaccount_id).Id;
                        consentRecord.PrivacyConsentStatus = req.post_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.post_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';  
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentsToUpsertMap.put(consentRecord.Id, consentRecord);
                    }                  
                }
                
                // SMS Consent
                if (req.sms_consent != null && req.sms_consent != '') {
                    // If Consent record does not exist but Consent preference has come through, create record
                    if (consentSmsMap.get(req.personaccount_id) == null) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'SMS - Marketing';
                        consentRecord.Channel__c = 'SMS';
                        consentRecord.DataUsePurposeId = marketingPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = req.sms_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.sms_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord);     
                    }
                    
                    // If Consent record does exist but Consent preference is different, update record            
                    else if (consentSmsMap.get(req.personaccount_id) != null && consentSmsMap.get(req.personaccount_id).PrivacyConsentStatus != consentOptInOutMap.get(req.sms_consent)) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Id = consentSmsMap.get(req.personaccount_id).Id;
                        consentRecord.PrivacyConsentStatus = req.sms_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.sms_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentsToUpsertMap.put(consentRecord.Id, consentRecord);
                    }                  
                }
                
                // Whatsapp Consent
                if (req.whatsapp_consent != null && req.whatsapp_consent != '') {
                    // If Consent record does not exist but Consent preference has come through, create record
                    if (consentWhatsappMap.get(req.personaccount_id) == null) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'WhatsApp - Marketing';
                        consentRecord.Channel__c = 'Whatsapp';
                        consentRecord.DataUsePurposeId = marketingPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = req.whatsapp_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.whatsapp_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord);    
                    }
                    
                    // If Consent record does exist but Consent preference is different, update record            
                    else if (consentWhatsappMap.get(req.personaccount_id) != null && consentWhatsappMap.get(req.personaccount_id).PrivacyConsentStatus != consentOptInOutMap.get(req.whatsapp_consent)) {
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Id = consentWhatsappMap.get(req.personaccount_id).Id;
                        consentRecord.PrivacyConsentStatus = req.whatsapp_consent == 'TRUE' ? 'OptIn' : 'OptOut'; 
                        consentRecord.Consent_Statement__c = req.whatsapp_consent == 'TRUE' ? consentStatementMap.get(req.data_source) : '';
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentsToUpsertMap.put(consentRecord.Id, consentRecord);
                    }                  
                }
                
                // Social Sync Registration - Mass Participation Email Consent
                if (req.data_source == 'Social Sync Registration') {
                    // If Consent record does not exist, create additional Email Consent record
                    if (consentMassParticipationMap.get(req.personaccount_id) == null) { 
                        ContactPointTypeConsent consentRecord = new ContactPointTypeConsent();
                        consentRecord.Name = 'Email - Mass Participation';
                        consentRecord.Channel__c = 'Email';
                        consentRecord.DataUsePurposeId = emailMassParticipationPurposeId;
                        consentRecord.Legal_Basis__c = 'Consent';
                        consentRecord.Person_Account__c = req.personaccount_id;
                        consentRecord.Campaign__c = req.campaign_id;
                        consentRecord.PartyId = accToIndvMap.get(req.personaccount_id);
                        consentRecord.PrivacyConsentStatus = 'OptIn'; 
                        consentRecord.Consent_Statement__c = consentStatementMap.get(req.data_source);
                        consentRecord.Consent_Capture_Source__c = consentCaptureSourceMap.get(req.data_source);
                        consentRecord.sj_FileSource__c = 'Data Cloud - ' + dataSource;
                        consentsToUpsert.add(consentRecord);    
                    }               
                }
            }
        } 
            
        consentsToUpsert.addAll(consentsToUpsertMap.values());
        System.debug(consentsToUpsert.size());
        System.debug(consentsToUpsert);
        //Database.upsert(consentsToUpsert, false);   
        upsert consentsToUpsert;
    }
        
    public class Request {        
        @InvocableVariable
        public String email_consent;        
        
        @InvocableVariable
        public String phone_consent;    
        
        @InvocableVariable
        public String post_consent;        
        
        @InvocableVariable
        public String sms_consent;  
        
        @InvocableVariable
        public String whatsapp_consent;  
                
        @InvocableVariable
        public String personaccount_id;     
        
        @InvocableVariable
        public String campaign_id;     
        
        @InvocableVariable
        public String data_source;     
    }
}