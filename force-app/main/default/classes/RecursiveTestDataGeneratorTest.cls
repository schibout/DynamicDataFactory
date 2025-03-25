@isTest
private class RecursiveTestDataGeneratorTest {
    
    
    @TestSetup
    static void setupTestData() {
        GlobalStoreDataTest.testDataLoad();
    }
    
    @isTest
    static void testRecursiveDataGeneration() {
        // Appeler la méthode principale de la classe RecursiveTestDataGenerator
        Id recordId =[SELECT Id FROM Contract LIMIT 1].Id;
        Test.startTest();
        RecursiveTestDataGenerator.generateTestDataWithLookups(recordId);
        RecursiveTestDataGenerator.commitRecords();
        Test.stopTest();
        List<SObjectTypeTestClasse__c> sobjectTypeTestClasseList =  [SELECT Id, Name FROM SObjectTypeTestClasse__c];
        // Vérifications (Assertions)
        System.assertNotEquals(null, sobjectTypeTestClasseList.size(), 'The SObjectTypeTestClasse__c list should not be null');
        System.assert(!sobjectTypeTestClasseList.isEmpty(), 'The SObjectTypeTestClasse__c list should not be empty');
        
    }
}