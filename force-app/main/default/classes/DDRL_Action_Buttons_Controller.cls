public class DDRL_Action_Buttons_Controller {

    @AuraEnabled(cacheable=true)
    public static String getButtons(String configId) {
        
        RecordResponse resp = new RecordResponse();
        resp.buttons = [SELECT Id,
                        		Name,
                        		variant__c,
                        		showIcon__c,
                        		iconName__c,
                        		iconPosition__c,
                        		tabIndex__c,
                        		horizontalPadding__c,
                        		actionType__c,
                                action__c
                           FROM DDRL_Action_Button__c
                          WHERE configId__c = :configId
                       ORDER BY tabIndex__c ASC];
        
        System.debug(resp.buttons);
        
        return JSON.serialize(resp);
    }
    
    public class RecordResponse {
        @AuraEnabled public List<DDRL_Action_Button__c> buttons;
    }
    
}