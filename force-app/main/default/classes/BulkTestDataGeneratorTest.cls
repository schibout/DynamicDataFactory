@isTest
private class BulkTestDataGeneratorTest {

    @TestSetup
    static void setupTestData() {
        GlobalStoreDataTest.testDataLoad();
    }
     @isTest
    static void testBulkRecursiveDataGeneration() {
        // Appeler la méthode principale de la classe RecursiveTestDataGenerator
        List<TimeSheetEntry__c> timeSheetEntries =[SELECT Id FROM TimeSheetEntry__c ];
        List<Id> recordIds = new List<Id>();
        for(TimeSheetEntry__c record : timeSheetEntries){
            recordIds.add(record.Id);
        }
        Test.startTest();
        BulkTestDataGenerator.generateTestDataWithLookups(recordIds);
        BulkTestDataGenerator.commitRecords();
        
        Test.stopTest();
        List<SObjectTypeTestClasse__c> sobjectTypeTestClasseList =  [SELECT Id, Name FROM SObjectTypeTestClasse__c];
        // Vérifications (Assertions)
        System.assertNotEquals(null, sobjectTypeTestClasseList.size(), 'The SObjectTypeTestClasse__c list should not be null');
        System.assert(!sobjectTypeTestClasseList.isEmpty(), 'The SObjectTypeTestClasse__c list should not be empty');
        
    }
}