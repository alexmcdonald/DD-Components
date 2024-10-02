public class DDRL_Child_Related_List_Controller {

    @AuraEnabled(cacheable=true)
    public static RecordResponse getChildRelatedList(String recordId, String objectApiName, String configId) {
        
        DDRL_Config__c config = [SELECT Id,
                                        Name,
                                        dcObjectName__c,
                                 		parentIdentifierField__c,
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
        
        Set<String> selectFields = new Set<String>{ 'Id', config.parentIdentifierField__c };
        
        String parentQuery = 'SELECT '+String.join(selectFields, ',');
        Boolean hasKQField = false;
        if(!String.isBlank(config.keyQualifierField__c)) {
            hasKQField = true;
            parentQuery += ', '+config.keyQualifierField__c;
        }
        parentQuery += ' FROM '+objectApiName+' WHERE Id=\''+recordId+'\' LIMIT 1';
        
        System.debug('** Parent Query: '+parentQuery);

        sObject parentRecord = Database.query(parentQuery);
        
        System.debug('** Parent Record: '+parentRecord);
        
        ParentConfig pc = new ParentConfig();
        pc.recordId = recordId;
        pc.objectApiName = objectApiName;
        pc.idField = config.parentIdentifierField__c;
        pc.idValue = (String)parentRecord.get(config.parentIdentifierField__c);
        pc.hasKq = hasKQField;
        if(pc.hasKq) {
            pc.kqField = config.keyQualifierField__c;
            pc.kqValue = (String)parentRecord.get(config.keyQualifierField__c);
        }

        System.debug('Parent Identifier: '+pc.idValue);
        
        String records = queryRecords(pc, config);
        
        System.debug('Records: '+records);
        
        RecordResponse resp = new RecordResponse();
        resp.records = records;
        resp.columns = JSON.serialize(columns);
        resp.keyField = config.uidField__c;
        resp.config = JSON.serialize(config);
        resp.parentDcId = pc.idValue;
        
        System.debug(JSON.serialize(resp));
        
        return resp;

    }
    
    public static String queryRecords(ParentConfig pc, DDRL_Config__c config) {
        
        // Build Overall WHERE Clause
        String whereClause = ' WHERE ( ' + config.parentIdentifierThisObject__c + ' = \'' + pc.idValue + '\' ';
        if(pc.hasKq) whereClause += 'AND ' + pc.kqField + ' = \'' + pc.kqValue +'\' ';
        whereClause += ') ';
        
        if(!String.isBlank(config.additionalWhereClause__c)) whereClause += 'AND (' + config.additionalWhereClause__c + ') ';
        
        String query = config.selectStatement__c + whereClause + config.orderByClause__c;
        System.debug('**** Data Cloud Records SOQL Query: ' + query);
        
        List<sObject> sobjs = Database.query(query);
        
        String records = '[]';
        
        if(sobjs.size() > 0) {
            records = '[';
            Boolean first = true;
            for(sObject sobj : sobjs) {
                if(first) {
                    first = false;
                } else {
                    records += ', ';
                }
                records += JSON.serialize(sobj);
            }
            records += ']';
        }

        return records;
    }
    
    private class ParentConfig {
        private String idField;
        private String idValue;
        private Boolean hasKq;
        private String kqField;
        private String kqValue;
        private String recordId;
        private String objectApiName;
    }
    
    public class RecordResponse {
        @AuraEnabled public String records;
        @AuraEnabled public String columns;
        @AuraEnabled public String keyField;
        @AuraEnabled public String config;
        @AuraEnabled public String parentDcId;
    }
        
    
}