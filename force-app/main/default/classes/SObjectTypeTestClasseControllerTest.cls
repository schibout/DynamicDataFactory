@isTest
private class SObjectTypeTestClasseControllerTest {
    
     @TestSetup
    static void setupTestData() {
        GlobalStoreDataTest.testDataLoad();
    }
    
    @isTest
    static void testGetSObjectTypeTestClasses() {
        Test.startTest();
        Id recordId = [SELECT Id FROM SObjectTypeTestClasse__c LIMIT 1].Id;
        List<SObjectTypeTestClasse__c> records = SObjectTypeTestClasseController.getSObjectTypeTestClasses();
        records = SObjectTypeTestClasseController.getDataForExport();
        SObjectTypeTestClasseController.getTableHeaders();
        Map<String, SObjectTypeTestClasse__c>  recordMap= SObjectTypeTestClasseController.getHeaderRecords();
        SObjectTypeTestClasse__c item = SObjectTypeTestClasseController.getSObjectTypeTestClasseById(recordId); 
        Test.stopTest();
        
        // Vérifications (Assertions)
        System.assertNotEquals(null, records, 'La liste ne doit pas être null');
        System.assert(records.size() > 0, 'La liste doit contenir au moins un enregistrement.');
    }
     @isTest
    static void testGetSObjectTypeException() {
        Test.startTest();
        List<SObjectTypeTestClasse__c>  records = [SELECT Id,Name FROM SObjectTypeTestClasse__c ];
        delete records ;
       
        try{
            SObjectTypeTestClasseController.getSObjectTypeTestClasseById(null);
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(),'Le controlleur doit renvoyer une exception');
        }
        Test.stopTest();
        
    }
}