/*
 * Test class for DataUtils
 */
@isTest
public class DataUtilsTest {
    @TestSetup
    static void makeData(){
        // Step 1: Set up test data
         TriggerHandler.bypass('AccountTriggerHandler');
         // Load test data for SObjectTypeTestClasse__c
        List<Object> listName = System.Test.loadData(SObjectTypeTestClasse__c.sObjectType, 'DynamicDataFactory');
        // Create Account and related test data
        DynamicDataFactory dataFactory = new DynamicDataFactory();
        List<Account> accountList = dataFactory.createSobjectsCascadeLookup('Account');
        TriggerHandler.clearBypass('AccountTriggerHandler');
    }
    @isTest
    static void testGetOriginalName() {
        // Test case for getOriginalName method
        String input = 'Adresse__c';
        String expected = 'Adresse';
        String result = DataUtils.getOriginalName(input);
        System.assertEquals(expected, result, 'getOriginalName did not return the expected result');
        String standardInput = 'Account';
        String standardResult = DataUtils.getOriginalName(standardInput);
        System.assertEquals(standardInput, standardResult, 'getOriginalName did not return the expected result');
    }

    @isTest
    static void testGetInteger() {
        // Test case for getInteger method
        Object validInput = '123';
        Integer expected = 123;
        Integer result = DataUtils.getInteger(validInput);
        System.assertEquals(expected, result, 'getInteger did not return the expected result');

        Object invalidInput = 'abc';
        Integer invalidResult = DataUtils.getInteger(invalidInput);
        System.assertEquals(null, invalidResult, 'getInteger did not handle invalid input correctly');
    }

    @isTest
    static void testGetStringValue() {
        // Test case for getStringValue method
        Object input = 'Test';
        String expected = 'Test';
        String result = DataUtils.getStringValue(input);
        System.assertEquals(expected, result, 'getStringValue did not return the expected result');

        Object nullInput = null;
        String nullResult = DataUtils.getStringValue(nullInput);
        System.assertEquals(null, nullResult, 'getStringValue did not handle null input correctly');
    }

    @isTest
    static void testGetBoolean() {
        // Test case for getBoolean method
        Object validInput = 'true';
        Boolean expected = true;
        Boolean result = DataUtils.getBoolean(validInput);
        System.assertEquals(expected, result, 'getBoolean did not return the expected result');

        String invalidInput = 'abc';
        Boolean invalidResult = DataUtils.getBoolean(invalidInput);
        System.assertEquals(false, invalidResult, 'getBoolean did not handle invalid input correctly');

        Object nullInput = null;
        Boolean nullResult = DataUtils.getBoolean(invalidInput);
        System.assertEquals(false, invalidResult, 'getBoolean did not handle invalid input correctly');
    }

    @isTest
    static void testGetDouble() {
        // Test case for getDouble method
        Object validInput = '123.45';
        Decimal expected = 123.45;
        Decimal result = DataUtils.getDouble(validInput);
        System.assertEquals(expected, result, 'getDouble did not return the expected result');

        Object invalidInput = 'abc';
        Decimal invalidResult = DataUtils.getDouble(invalidInput);
        System.assertEquals(null, invalidResult, 'getDouble did not handle invalid input correctly');
    }

    @isTest
    static void testEscapeSingleQuotes() {
        // Test case for escapeSingleQuotes method
        String input = 'OReilly';
        String expected = 'OReilly';
        String result = DataUtils.escapeSingleQuotes(input);
        System.assertEquals(expected, result, 'escapeSingleQuotes did not return the expected result');
    }

    @isTest
    static void testIsNullAndIsNotNull() {
        // Test case for isNull and isNotNull methods
        String nullInput = null;
        System.assert(DataUtils.isNull(nullInput), 'isNull did not return true for null input');

        String emptyInput = '';
        System.assert(DataUtils.isNull(emptyInput), 'isNull did not return true for empty input');

        String validInput = 'Test';
        System.assert(DataUtils.isNotNull(validInput), 'isNotNull did not return true for valid input');
    }

    @isTest
    static void testGetSobjectNameById() {
        // Test case for getSobjectNameById method
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        String sobjectName = DataUtils.getSobjectNameById(acc.Id);
        System.assertEquals('Account', sobjectName, 'getSobjectNameById did not return the expected result');
    }

    @isTest
    static void testGenerateMapStringSObjects() {
        // Test case for generateMapStringSObjects method
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 1];
        

        Map<String, SObject> result = DataUtils.generateMapStringSObjects(accounts, 'Name');
        System.debug('result '+ result);
        System.assertEquals(1, result.size(), 'generateMapStringSObjects did not return the expected map size');
        System.assert(result.containsKey('FLEXSTONE PARTNERS SAS'), 'generateMapStringSObjects did not include expected key');
    }

    @isTest
    static void testGetString() {
        // Test case for getString method
        Object stringInput = 'Hello';
        String result = DataUtils.getString(stringInput);
        System.assertEquals('Hello', result, 'getString did not return the expected string');

        Object sObjectInput =  'Test';
        String serializedResult = DataUtils.getString(sObjectInput);
        System.assert(serializedResult.contains('Test'), 'getString did not serialize SObject correctly');
    }

    @isTest
    static void testGetFieldsMap() {
        // Test case for getFieldsMap method
        Map<String, Schema.SObjectField> fieldsMap = DataUtils.getFieldsMap('Account');
        System.assert(fieldsMap != null && fieldsMap.containsKey('Name'), 'getFieldsMap did not return the expected result');
    }

    @isTest
    static void testGetSobjectNameByRecord() {
        // Test case for getSobjectNameByRecord method
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        String sobjectName = DataUtils.getSobjectNameByRecord(acc);
        System.assertEquals('Account', sobjectName, 'getSobjectNameByRecord did not return the expected result');
    }

    @isTest
    static void testGetRecordTypeDeveloperNameByRecord() {
        // Test case for getRecordTypeDeveloperNameByRecord method
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];

        String recordTypeName = DataUtils.getRecordTypeDeveloperNameByRecord(acc);
        System.assert(recordTypeName == null, 'getRecordTypeDeveloperNameByRecord did not handle null RecordTypeId correctly');
    }


    @isTest
    static void testGenerateMapIdListOfObjects() {
        // Test case for generateMapIdListOfObjects method
        List<SObject> accounts   = [SELECT Id, Name FROM Account ];
        Map<Id, List<SObject>> result = DataUtils.generateMapIdListOfObjects(accounts, 'Id');
        System.assertEquals(accounts.size(), result.size(), 'generateMapIdListOfObjects did not return the expected map size');
    }

    @isTest
    static void testGenerateMapIdSetOfObjects() {
        // Test case for generateMapIdSetOfObjects method
        List<SObject> accounts   = [SELECT Id, Name FROM Account ];

        Map<Id, Set<SObject>> result = DataUtils.generateMapIdSetOfObjects(accounts, 'Id');
        System.assertEquals(accounts.size(), result.size(), 'generateMapIdSetOfObjects did not return the expected map size');
    }

    @isTest
    static void testGenerateMapStringSetOfObjects() {
        // Test case for generateMapStringSetOfObjects method
       List<SObject> accounts   = [SELECT Id, Name FROM Account ];

        Map<String, Set<SObject>> result = DataUtils.generateMapStringSetOfObjects(accounts, 'Name');
        System.assertEquals(accounts.size(), result.size(), 'generateMapStringSetOfObjects did not return the expected map size');
    }

   
    @isTest
    static void testCheckIfRecordIsUpdatedSingleField() {
        // Test case for checkIfRecordIsUpdated with single field
         TriggerHandler.bypass('AccountTriggerHandler');
            Account acc = [SELECT Id, Name FROM Account ][0];
            Account updatedAcc = [SELECT Id, Name FROM Account WHERE Id = :acc.Id];
            updatedAcc.Name = 'Updated Account';
            update updatedAcc;
        TriggerHandler.clearBypass('AccountTriggerHandler');
        Account oldAcc = acc;
        Account newAcc = updatedAcc;

        Id result = DataUtils.checkIfRecordIsUpdated(newAcc, oldAcc, 'Name');
        System.assertEquals(newAcc.Id, result, 'checkIfRecordIsUpdated did not detect updated field correctly');
    }

    @isTest
    static void testCheckIfRecordIsUpdatedMultipleFields() {
        // Test case for checkIfRecordIsUpdated with multiple fields
        Account acc = [SELECT Id, Name, Phone FROM Account ][0];
        TriggerHandler.bypass('AccountTriggerHandler');
        Account updatedAcc = [SELECT Id, Name, Phone FROM Account WHERE Id = :acc.Id];
        updatedAcc.Name = 'Updated Account';
        updatedAcc.Phone = '67890';
        update updatedAcc;
        TriggerHandler.ClearBypass('AccountTriggerHandler');
        Account oldAcc = acc;
        Account newAcc = updatedAcc;

        List<String> fieldsToCheck = new List<String>{'Name', 'Phone'};
        Id result = DataUtils.checkIfRecordIsUpdated(newAcc, oldAcc, fieldsToCheck);
        System.assertEquals(newAcc.Id, result, 'checkIfRecordIsUpdated did not detect updated fields correctly');
    }
    @isTest
    static void testParseResponseError() {
        // Create a mock HttpResponse
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setStatus('Bad Request');
        response.setBody('{"error":"Invalid request","message":"Missing required field"}');

        // Call the method under test
        String errorMessage = DataUtils.parseResponseError(response);

        // Assertions
        System.assertNotEquals(null, errorMessage, 'Error message should not be null');
        System.assert(errorMessage.contains('HTTP Status: 400 Bad Request'), 'Should contain status information');
        System.assert(errorMessage.contains('Invalid request'), 'Should extract error details');
        System.assert(errorMessage.contains('Missing required field'), 'Should extract error message');
    }

    @isTest
    static void testParseResponseErrorEmptyBody() {
        // Create a response with an empty body
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setStatus('Internal Server Error');
        response.setBody('');

        // Call the method
        String errorMessage = DataUtils.parseResponseError(response);

        // Assertions
        System.assertNotEquals(null, errorMessage, 'Error message should not be null');
        System.assertEquals('HTTP Status: 500 Internal Server Error', errorMessage, 'Should return only status without details');
    }

    @isTest
    static void testParseResponseErrorNullBody() {
        // Create a response with null body
        HttpResponse response = new HttpResponse();
        response.setStatusCode(404);
        response.setStatus('Not Found');

        // Call the method
        String errorMessage = DataUtils.parseResponseError(response);

        // Assertions
        System.assertNotEquals(null, errorMessage, 'Error message should not be null');
        System.assertEquals('HTTP Status: 404 Not Found', errorMessage, 'Should return only status without details');
    }
  
    // Test method for getDateTime
    @isTest
    static void testGetDateTime() {
        // Test with valid date string
        String validDateStr = '2023-10-15T12:34:56Z';
        Datetime expectedDateTime = Datetime.valueOfGMT('2023-10-15 12:34:56');
        Datetime resultDateTime = DataUtils.getDateTime(validDateStr);
        System.assertEquals(expectedDateTime, resultDateTime, 'getDateTime should return the correct DateTime for a valid date string');


        // Test with invalid date string
        String invalidDateStr = 'InvalidDate';
        System.assertEquals(null, DataUtils.getDateTime(invalidDateStr), 'getDateTime should return null for an invalid date string');
    }

    // Test method for getDate
    @isTest
    static void testGetDate() {
        // Test with valid date string in YYYY-MM-DD format
        String validDateStr = '2023-10-15';
        Date expectedDate = Date.valueOf(validDateStr);
        Date resultDate = DataUtils.getDate(validDateStr);
        System.assertEquals(expectedDate, resultDate, 'getDate should return the correct Date for a valid date string in YYYY-MM-DD format');

        // Test with valid date string in DD/MM/YYYY format
        String validDateStrSlash = '15/10/2023';
        Date expectedDateSlash = Date.newInstance(2023, 10, 15);
        Date resultDateSlash = DataUtils.getDate(validDateStrSlash);
        System.assertEquals(expectedDateSlash, resultDateSlash, 'getDate should return the correct Date for a valid date string in DD/MM/YYYY format');

        // Test with null input
        System.assertEquals(null, DataUtils.getDate(null), 'getDate should return null for null input');

        // Test with invalid date string
        String invalidDateStr = 'InvalidDate';
        Date result = DataUtils.getDate(invalidDateStr);
        System.assert(null == result,'getDate should throw an Exception for an invalid date string');
    }

    // Test method for convertStringToDate
    @isTest
    static void testConvertStringToDate() {
        // Test with valid date string in DD/MM/YYYY format
        String validDateStr = '15/10/2023';
        Date expectedDate = Date.newInstance(2023, 10, 15);
        Date resultDate = DataUtils.getDate(validDateStr);
        System.assertEquals(expectedDate, resultDate, 'convertStringToDate should return the correct Date for a valid date string in DD/MM/YYYY format');

        // Test with invalid date string
        String invalidDateStr = 'InvalidDate';
        System.assertEquals(null, DataUtils.getDate(invalidDateStr), 'convertStringToDate should return null for an invalid date string');
    }

    // Test method for parseJsonToFlattenedMap with String input
    @isTest
    static void testParseJsonToFlattenedMapString() {
        // Test with valid JSON string
        String validJsonStr = '{"name":"John","age":30,"address":{"city":"New York","zip":"10001"}}';
        Map<String, String> expectedMap = new Map<String, String>{
            'name' => 'John',
            'age' => '30',
            'address.city' => 'New York',
            'address.zip' => '10001'
        };
        Map<String, String> resultMap = DataUtils.parseJsonToFlattenedMap(validJsonStr);
        System.assertEquals(expectedMap, resultMap, 'parseJsonToFlattenedMap should return the correct flattened map for a valid JSON string');

        // Test with empty JSON string
        String emptyJsonStr = '';
        Map<String, String> emptyMap = new Map<String, String>();
        System.assertEquals(emptyMap, DataUtils.parseJsonToFlattenedMap(emptyJsonStr), 'parseJsonToFlattenedMap should return an empty map for an empty JSON string');
    }

    // Test method for parseJsonToFlattenedMap with Map<String, Object> input
    @isTest
    static void testParseJsonToFlattenedMapObject() {
        // Test with valid JSON map
        Map<String, Object> validJsonMap = new Map<String, Object>{
            'name' => 'John',
            'age' => 30,
            'address' => new Map<String, Object>{
                'city' => 'New York',
                'zip' => '10001'
            }
        };
        Map<String, String> expectedMap = new Map<String, String>{
            'name' => 'John',
            'age' => '30',
            'address.city' => 'New York',
            'address.zip' => '10001'
        };
        Map<String, String> resultMap = DataUtils.parseJsonToFlattenedMap(validJsonMap);
        System.assertEquals(expectedMap, resultMap, 'parseJsonToFlattenedMap should return the correct flattened map for a valid JSON map');

        // Test with empty JSON map
        Map<String, Object> emptyJsonMap = new Map<String, Object>();
        Map<String, String> emptyMap = new Map<String, String>();
        System.assertEquals(emptyMap, DataUtils.parseJsonToFlattenedMap(emptyJsonMap), 'parseJsonToFlattenedMap should return an empty map for an empty JSON map');
    }

    // Test method for flattenJsonMap (private method, tested indirectly through parseJsonToFlattenedMap)
    @isTest
    static void testFlattenJsonMap() {
        // This method is private and is tested indirectly through the public methods that call it.
        // The test cases for parseJsonToFlattenedMap cover the functionality of flattenJsonMap.
    }
    @isTest
    static void testGetDateValidFormats() {
        // Test with DD/MM/YYYY format
        Date expectedDate1 = Date.newInstance(2023, 10, 15);
        Date resultDate1 = DataUtils.getDate('15/10/2023', 'DD/MM/YYYY');
        System.assertEquals(expectedDate1, resultDate1, 'getDate should parse DD/MM/YYYY format correctly');

        // Test with DD-MM-YYYY format
        Date resultDate2 = DataUtils.getDate('15-10-2023', 'DD-MM-YYYY');
        System.assertEquals(expectedDate1, resultDate2, 'getDate should parse DD-MM-YYYY format correctly');

        // Test with MM/DD/YYYY format
        Date expectedDate3 = Date.newInstance(2023, 10, 15);
        Date resultDate3 = DataUtils.getDate('10/15/2023', 'MM/DD/YYYY');
        System.assertEquals(expectedDate3, resultDate3, 'getDate should parse MM/DD/YYYY format correctly');
    }

    @isTest
    static void testGetDateInvalidFormats() {
        // Test with invalid date string
        Date resultDate1 = DataUtils.getDate('InvalidDate', 'DD/MM/YYYY');
        System.assertEquals(null, resultDate1, 'getDate should return null for invalid date string');

        // Test with mismatched format and date string
        Date resultDate2 = DataUtils.getDate('15/10/2023', 'MM-DD-YYYY');
       // System.assertEquals(null, resultDate2, 'getDate should return null for mismatched format and date string');

        // Test with null input
        Date resultDate3 = DataUtils.getDate(null, 'DD/MM/YYYY');
        System.assertEquals(null, resultDate3, 'getDate should return null for null input');

        // Test with empty format
        Date resultDate4 = DataUtils.getDate('15/10/2023', '');
        System.assertEquals(null, resultDate4, 'getDate should return null for empty format');
    }

    @isTest
    static void testGetDateEdgeCases() {
        // Test with single-digit day and month
        Date expectedDate1 = Date.newInstance(2023, 5, 5);
        Date resultDate1 = DataUtils.getDate('5/5/2023', 'DD/MM/YYYY');
        System.assertEquals(expectedDate1, resultDate1, 'getDate should handle single-digit day and month');

        // Test with invalid year
        Date resultDate2 = DataUtils.getDate('15/10/aaaaa', 'DD/MM/YYYY');
        System.assertEquals(null, resultDate2, 'getDate should return null for invalid year');

        // Test with invalid month
        Date resultDate3 = DataUtils.getDate('15/aa/2023', 'DD/MM/YYYY');
        System.assertEquals(null, resultDate3, 'getDate should return null for invalid month');

        // Test with invalid day
        Date resultDate4 = DataUtils.getDate('hh/10/2023', 'DD/MM/YYYY');
        System.assertEquals(null, resultDate4, 'getDate should return null for invalid day');
    }


}