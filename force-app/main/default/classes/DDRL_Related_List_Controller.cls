/*
 * Controller for the ddrlRelatedList LWC. The LWC can be added to any standard Salesforce record page.  It is not supported on a Data Cloud record page, instead use
 * the ddrlChildRelatedList component. This variant of the component is for use in Data Cloud host orgs, not orgs that connect soley via Data Cloud APIs.
 * 
 * The component uses Dynamic SOQL to query the Data Cloud linked profiles and records. In theory this should be faster and easier to maintain than API-based integration.
 * 
 */

public class DDRL_Related_List_Controller {

    @AuraEnabled(cacheable=true)
    public static RecordResponse getRelatedList(String recordId, String configId, String objectApiName, String dataSourceId, String dataSourceObjectId, String individualIdentityLinkObject, String recordContactField) {
        
        // The component is designed to be dropped onto any page that's linked to a contact/lead/other individual record.  The recordContactField parameter specifies the path to that record.
        // eg. on a case it might be ContactId. On a Work Order linked to that case it might be Case.ContactId. This routine navigates up the record hierarchy to ultimately find the
        // contact/lead/other's record Id.
        if(!String.isBlank(recordContactField) && recordContactField.toLowercase() != 'id') {
	        String recordQuery = 'SELECT '+recordContactField+' FROM '+objectApiName+' WHERE Id=\''+recordId+'\'';
            System.debug('**Record Query: '+recordQuery);
            SObject s = Database.query(recordQuery);
            List<String> fieldParts = recordContactField.split('\\.');
            while(fieldParts.size() > 1) {
      			s = s.getSObject(fieldParts.remove(0));
    		}
            recordId = (String)s.get(fieldParts[0]);
            System.debug(recordId);
        }
        
		// The config and columns records determine which fields will be queries and how columns should be displayed        
        DDRL_Config__c config = [SELECT Id,
                                        Name,
                                        dcObjectName__c,
                                 		parentIdentifierThisObject__c,
                                        keyQualifierField__c,
                                 		selectStatement__c,
                                 		additionalWhereClause__c,
                                 		orderByClause__c,
                                        uidField__c
                                   FROM DDRL_Config__c 
                                  WHERE Id=:configId];
        List<DDRL_Column__c> columns = [SELECT Id,
                                               Name,
                                               label__c,
                                               type__c,
                                               displayType__c,
                                               decimalPlaces__c,
                                               currencyCode__c,
                                               day__c,
                                               month__c,
                                               year__c,
                                        	   hour__c,
                                               minute__c,
                                               second__c,
                                               timeZone__c,
                                               order__c,
                                               alignment__c,
                                               width__c,
                                        	   wrapText__c,
                                        	   isLink__c,
                                               linkFormat__c
                                          FROM DDRL_Column__c
                                         WHERE config__c = :configId
                                      ORDER BY order__c ASC];
        
        // This method identifies all the linked individual records from different systems that make up this individuals unified profile.
        List<sObject> linkedIndividuals = getLinkedIndividuals(recordId, objectApiName, dataSourceId, dataSourceObjectId, individualIdentityLinkObject);

        // This method queries the Data Cloud object as specified in the config, restricting the query to only those records related to a linked individual
        String records = queryRecords(linkedIndividuals, config);
        
        RecordResponse resp = new RecordResponse();
        resp.records = records;
        resp.columns = JSON.serialize(columns);
        resp.keyField = config.uidField__c;
        
        return resp;
    }
    
    public static List<sObject> getLinkedIndividuals(String recordId, String objectApiName, String dataSourceId, String dataSourceObjectId, String individualIdentityLinkObject) {
        
        /* Commenting out to support non-B2C Orgs
        if(objectApiName == 'Account') {
            System.debug('recordId: '+recordId);
            Account a = [SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id=:recordId];
            System.debug('Account: '+a);
            if(a.isPersonAccount) recordId = a.PersonContactId;
        }
        */
        
        String individualQuery = 'SELECT UnifiedRecordId__c FROM '+individualIdentityLinkObject+' WHERE SourceRecordId__c=\''+recordId+'\' AND ssot__DataSourceId__c = \''+dataSourceId+'\' AND ssot__DataSourceObjectId__c = \''+dataSourceObjectId+'\' LIMIT 1';

        sObject individualLinkRecord;
        String unifiedRecordId;
        
        try {
            individualLinkRecord = Database.Query(individualQuery);
            unifiedRecordId = (String)individualLinkRecord.get('UnifiedRecordId__c');
        } catch(Exception e) {
            if(Test.isRunningTest()) {
                unifiedRecordId = recordId;
            }
        }
        
        List<sObject> linkedIndividuals = null;
        
        if(Test.isRunningTest()) {
            linkedIndividuals = Database.Query('SELECT Id FROM Account WHERE Id=\''+recordId+'\'');
        } else {
	        linkedIndividuals = Database.Query('SELECT UnifiedRecordId__c, ssot__DataSourceId__c, ssot__DataSourceObjectId__c, SourceRecordId__c, KQ_SourceRecordID__c FROM '+individualIdentityLinkObject+' WHERE UnifiedRecordId__c = \''+unifiedRecordId+'\'');            
        }

        
        System.debug('** Linked Individuals: '+linkedIndividuals);
        return linkedIndividuals;
        
    }
    
    public static String queryRecords(List<sObject> linkedIndividuals, DDRL_Config__c config) {
        
        // Build Overall WHERE Clause
        List<String> whereClauses = new List<String>();        
	    for(sObject ind : linkedIndividuals) {
            String wC = (!Test.isRunningTest()) ? '( ' + config.parentIdentifierThisObject__c + ' = \'' + (String)ind.get('SourceRecordId__c') + '\' ' : '( AccountId = \''+ind.get('Id')+'\' ';
            if(!String.isBlank(config.keyQualifierField__c)) wC += 'AND ' + config.keyQualifierField__c + ' = \'' + (String)ind.get('KQ_SourceRecordId__c') +'\' ';
            wC += ')';
            whereClauses.add(wC);
        }
        String whereClause = '';
        if(whereClauses.size() > 0) {
            whereClause += ' WHERE (' + String.join(whereClauses, ' OR ') + ') ';
            if(!String.isBlank(config.additionalWhereClause__c)) whereClause += 'AND (' + config.additionalWhereClause__c + ') ';
            
        	String query = config.selectStatement__c + whereClause + config.orderByClause__c;
        	System.debug('**** Data Cloud Records SOQL Query: ' + query);

            List<sObject> sobjs = Database.query(query);
            
            // No idea why, but lists of plain sObjects won't serialize to JSON strings.
            // So this routine loops through the returned records and serializes them one by one.
            String records = '[]';
            if(sobjs.size() >0) {
                records='[';
                Boolean first = true;
                for(SObject sobj : sobjs) {
                    if(first) {
                        first=false;
                    } else {
                        records += ', ';
                    }
                    records += JSON.serialize(sobj);
                }
                records += ']';
            }
            
            System.debug(records);
            return records;
        }
        
        return null;
    }
    
    public class RecordResponse {
        @AuraEnabled public String records;
        @AuraEnabled public String columns;
        @AuraEnabled public String keyField;
    }
        
    
}