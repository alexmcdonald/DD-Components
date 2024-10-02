@isTest
public class DDRL_Unit_Tests {

    @testSetup static void testSetup() {
        
        Account a = new Account();
        a.Name = 'Test';
        insert(a);
        
        Contact ct = new Contact();
        ct.FirstName = 'Test';
        ct.LastName = 'Test';
        ct.AccountId = a.Id;
        insert(ct);
        
        Case c = new Case();
        c.Subject = 'Test';
        c.ContactId = ct.Id;
        c.AccountId = a.Id;
        insert(c);
        
        CaseComment cc1 = new CaseComment();
        cc1.ParentId = c.Id;
        cc1.CommentBody = 'Test Comment 1';
        insert(cc1);
        
        CaseComment cc2 = new CaseComment();
        cc2.ParentId = c.Id;
        cc2.CommentBody = 'Test Comment 2';
        insert(cc2);
        
        Case c2 = new Case();
        c2.Subject = 'Test2';
        c2.ContactId = ct.Id;
        c2.AccountId = a.Id;
        insert(c2);
        
        DDRL_Config__c config = new DDRL_Config__c();
        config.Name = 'Test Config';
        config.dcObjectName__c = 'Case';
        config.uidField__c = 'Id';
        config.selectStatement__c = 'SELECT Id, Subject, Status, Priority, CreatedDate FROM Case';
        config.orderByClause__c = 'ORDER BY CreatedDate DESC LIMIT 5';
        config.parentIdentifierField__c = 'Id';
        config.parentIdentifierThisObject__c = 'Id';
        insert(config);
        
        DDRL_Column__c col1 = new DDRL_Column__c();
        col1.Name = 'Subject';
        col1.label__c = 'Subject';
        col1.isLink__c = true;
        col1.config__c = config.Id;
        col1.linkFormat__c = '/lightning/r/Case/{{Id}}/view';
        col1.order__c = 10;
        col1.type__c = 'Text';
        col1.displayType__c = 'Text';
        insert(col1);
        
        DDRL_Column__c col2 = new DDRL_Column__c();
        col2.Name='Status';
        col2.label__c = 'Status';
        col2.isLink__c = false;
        col2.config__c = config.Id;
        col2.order__c = 20;
        col2.type__c = 'Text';
        col2.displayType__c = 'Text';
        insert(col2);
        
        DDRL_Column__c col3 = new DDRL_Column__c();
        col3.Name='CreatedDate';
        col3.label__c = 'Created Date';
        col3.isLink__c = false;
        col3.config__c = config.Id;
        col3.order__c = 30;
        col3.type__c = 'DateTime';
        col3.displayType__c = 'DateTime';
        col3.day__c = '2-digit';
        col3.month__c = '2-digit';
        col3.year__c = 'numeric';
        col3.hour__c = 'numeric';
        col3.minute__c = '2-digit';
        col3.second__c = '';
        col3.timeZone__c = 'America/Los_Angeles';
        insert(col3);
        
        DDRL_Action_Button__c action1 = new DDRL_Action_Button__c();
        action1.Name = 'Test Action';
        action1.variant__c = 'Brand';
        action1.showIcon__c = true;
        action1.iconPosition__c = 'Left';
        action1.iconName__c = 'utility:close';
        action1.tabIndex__c = -1;
        action1.horizontalPadding__c = 'xx-small';
        action1.actionType__c = 'Flow';
        action1.action__c = 'Test';
        action1.configId__c = config.Id;
		insert(action1);
        
        DDRL_Config__c config2 = new DDRL_Config__c();
        config2.Name = 'Test Config2';
        config2.dcObjectName__c = 'CaseComment';
        config2.uidField__c = 'Id';
        config2.selectStatement__c = 'SELECT Id, CommentBody, CreatedDate FROM CaseComment';
        config2.orderByClause__c = 'ORDER BY CreatedDate DESC LIMIT 5';
        config2.parentIdentifierField__c = 'Id';
        config2.parentIdentifierThisObject__c = 'ParentId';
        insert(config2);
        
        DDRL_Column__c col21 = new DDRL_Column__c();
        col21.Name = 'CommentBody';
        col21.label__c = 'Comment';
        col21.isLink__c = true;
        col21.config__c = config2.Id;
        col21.linkFormat__c = '/lightning/r/CaseComment/{{Id}}/view';
        col21.order__c = 10;
        col21.type__c = 'Text';
        col21.displayType__c = 'Text';
        insert(col21);
        
        DDRL_Column__c col22 = new DDRL_Column__c();
        col22.Name='CreatedDate';
        col22.label__c = 'Created Date';
        col22.isLink__c = false;
        col22.config__c = config2.Id;
        col22.order__c = 30;
        col22.type__c = 'DateTime';
        col22.displayType__c = 'DateTime';
        col22.day__c = '2-digit';
        col22.month__c = '2-digit';
        col22.year__c = 'numeric';
        col22.hour__c = 'numeric';
        col22.minute__c = '2-digit';
        col22.second__c = '';
        col22.timeZone__c = 'America/Los_Angeles';
        insert(col22);
        
    }

    
    @isTest static void TestRelatedList() {
        
        DDRL_Config__c config = [SELECT Id FROM DDRL_Config__c WHERE Name='Test Config'];
        Case c = [SELECT Id FROM Case WHERE Subject='Test'];

        Test.startTest();
        DDRL_Related_List_Controller.RecordResponse response = DDRL_Related_List_Controller.getRelatedList(c.Id, config.Id, 'Case', 'Salesforce_00DDn00000Dv8Sx', 'Contact', 'IndividualIdentityLink__dlm', 'Contact.Account.Id');
        Test.stopTest();
        
    }
    
    @isTest static void TestFilteredRelatedList() {

        DDRL_Config__c config = [SELECT Id FROM DDRL_Config__c WHERE Name='Test Config'];
        Case c = [SELECT Id FROM Case WHERE Subject='Test'];

        Test.startTest();
        DDRL_Filtered_Related_List_Controller.RecordResponse response = DDRL_Filtered_Related_List_Controller.getRelatedList(c.Id, config.Id, 'Case', 'Salesforce_00DDn00000Dv8Sx', 'Contact', 'IndividualIdentityLink__dlm', 'Contact.Account.Id');

        String filters = '{"startDate":"2024-01-01","test1__c":null,"test2__c":null,"endDate":"2024-04-30"}';
        
        String filteredRecords = DDRL_Filtered_Related_List_Controller.filterQueryRecords(response.recordQuery, filters, 'CreatedDate');

        Test.stopTest();
        
    }
    
    @isTest static void TestChildRelatedList() {
        
        DDRL_Config__c config = [SELECT Id FROM DDRL_Config__c WHERE Name='Test Config2'];
        Case c = [SELECT Id FROM Case WHERE Subject='Test'];

        Test.startTest();
        DDRL_Child_Related_List_Controller.RecordResponse response = DDRL_Child_Related_List_Controller.getChildRelatedList(c.Id, 'Case', config.Id);
        Test.stopTest();
        
    }
    
    @isTest static void TestActionButtons() {
        
        DDRL_Config__c config = [SELECT Id FROM DDRL_Config__c WHERE Name='Test Config'];

        Test.startTest();
        String buttons = DDRL_Action_Buttons_Controller.GetButtons(config.Id);
        Test.stopTest();

    }
    

}