@isTest
public class DD_Unit_Tests {

    @testSetup static void testSetup() {

		Account a = new Account();
        a.Name = 'Test';
        insert(a);
        
        Contact ct = new Contact();
        ct.FirstName = 'Test';
        ct.LastName = 'Test';
        ct.AccountId = a.Id;
        insert(ct);
        
    }


    
    @isTest static void TestGetLinkedIndividualId() {
        
        Account a = [SELECT Id FROM Account WHERE Name='Test'];
        
        DD_GetLinkedIndividualId.InputData input = new DD_GetLinkedIndividualId.InputData();
        input.individualIdentityLinkObject = 'Account';
        input.sourceRecordId = a.Id;
        input.kqSourceRecordId = 'DD';
        input.targetDataSourceId = 'Salesforce_00Dao000004rCc1';
        input.targetDataSourceObjectId = 'Contact';
    
        Test.startTest();
        List<DD_GetLinkedIndividualId.OutputData> output = DD_GetLinkedIndividualId.execute(new List<DD_GetLinkedIndividualId.InputData>{input});
        Test.stopTest();

    }
    
}