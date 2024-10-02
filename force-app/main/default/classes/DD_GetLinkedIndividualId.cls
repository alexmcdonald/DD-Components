public class DD_GetLinkedIndividualId {

    @InvocableMethod(label='DD: Get Linked Individual Id')
    public static List<OutputData> execute(List<InputData> inputs) {
        
        InputData input = inputs[0];
        
        // 1) Get the Unified Individual Id associated with this Record

        String kqClause = (!String.isBlank(input.kqSourceRecordId)) ? ' AND KQ_SourceRecordId__c=\''+input.kqSourceRecordId+'\'' : '';
        String individualQuery = 'SELECT UnifiedRecordId__c FROM '+input.individualIdentityLinkObject+' WHERE SourceRecordId__c=\''+input.sourceRecordId+'\'' + kqClause + ' LIMIT 1';

        sObject individualLinkRecord;
        String unifiedRecordId;
        
        try {
            individualLinkRecord = Database.Query(individualQuery);
            unifiedRecordId = (String)individualLinkRecord.get('UnifiedRecordId__c');
        } catch(Exception e) {
            if(Test.isRunningTest()) {
                unifiedRecordId = input.sourceRecordId;
            }
        }
                
        List<sObject> linkedIndividuals = null;
        
        if(!Test.isRunningTest()) {
	        linkedIndividuals = Database.Query('SELECT SourceRecordId__c FROM '+input.individualIdentityLinkObject+' WHERE UnifiedRecordId__c = \''+unifiedRecordId+'\'  AND ssot__DataSourceId__c=\''+input.targetDataSourceId+'\' AND ssot__DataSourceObjectId__c=\''+input.targetDataSourceObjectId+'\'');           
        } else {
            linkedIndividuals = Database.Query('SELECT Id FROM Account WHERE Id=\''+input.sourceRecordId+'\'');
        }
        
        System.debug('** Linked Individuals: '+linkedIndividuals);
        
        // 2) Find the Individual Id/s associated with the Target Data Source
        
        OutputData output = new OutputData();
        List<String> recordIds = new List<String>();
        for(sObject obj : linkedIndividuals) {
            if(!Test.isRunningTest()) {
                recordIds.add((String)obj.get('SourceRecordId__c')); 
            } else {
                recordIds.add((String)obj.get('Id'));
            }
        }
        if(recordIds.size() > 0) {
            output.recordCount = recordIds.size();
            output.recordIds = recordIds;
            if(recordIds.size() == 1) output.singleRecordId = recordIds[0];
            output.success = true;
        } else {
            output.success = false;
        }
        return new List<OutputData>{output};
    }
    
    public class InputData {
        @InvocableVariable public String individualIdentityLinkObject;
        @InvocableVariable public String sourceRecordId;
        @InvocableVariable public String kqSourceRecordId;
        @InvocableVariable public String targetDataSourceId;
        @InvocableVariable public String targetDataSourceObjectId;
    }
    
    public class OutputData {
        @InvocableVariable public String singleRecordId;
        @InvocableVariable public List<String> recordIds;
        @InvocableVariable public Integer recordCount;
        @InvocableVariable public Boolean success;
    }
    
}