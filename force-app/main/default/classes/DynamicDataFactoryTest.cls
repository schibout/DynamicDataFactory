/**
 * @description       : 
 * @author            : samir.chibout.ext@sodexo.com
 * @group             : 
 * @last modified on  : 18-01-2023
 * @last modified by  : samir.chibout.ext@sodexo.com
**/
@isTest
public with sharing class DynamicDataFactoryTest {
    @TestSetup
    static void makeData(){
        
        TriggerHandler.bypass('AccountTriggerHandler');
        List<Object> listName = System.Test.loadData(SObjectTypeTestClasse__c.sObjectType, 'DynamicDataFactory');
        TriggerHandler.ClearBypass('AccountTriggerHandler');
    }
    @IsTest
    static void testObjectCreation(){
            TriggerHandler.bypass('AccountTriggerHandler');
            DynamicDataFactory dataFactory = new DynamicDataFactory();
            List<Account> accountList = dataFactory.createSobjectsCascadeLookup('Account');
            System.assert(accountList.size() > 0, 'Account test data creation failed');
            List<Periode__c> periodeList = dataFactory.createSobjectsWithSpecificNameCascadeLookup('periode__c','periode_1');
            System.assert(periodeList.size() > 0, 'periodeList test data creation failed');
            // Create TimeSheet test data
            List<TimeSheet__c> timeSheetList = dataFactory.createSobjectsWithSpecificNameCascadeLookup('TimeSheet__c','TimeSheet_1');
            System.assert(timeSheetList.size() > 0, 'timeSheetList test data creation failed');
            TriggerHandler.ClearBypass('AccountTriggerHandler');

    }
    
}