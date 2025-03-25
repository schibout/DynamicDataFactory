/**
* @description       : Classe pour générer des données de test en masse avec gestion des lookups
* @author            : samir.chibout.ext@sodexo.com
* @last modified on  : 24-02-2025
**/
public with sharing class BulkTestDataGenerator {
    
    private static Set<String> processedIds = new Set<String>();
    private static Map<String, Boolean> objectHeaderCreated = new Map<String, Boolean>();
    private static Map<String, Integer> objectLineCounter = new Map<String, Integer>();
    private static Map<Id, String> idToLineNameMap = new Map<Id, String>();
    private static Map<String, List<SObjectTypeTestClasse__c>> pendingInsertsByType = new Map<String, List<SObjectTypeTestClasse__c>>();
    private static Map<String, Set<String>> objectToUsedFieldsMap = new Map<String, Set<String>>();
    private static Map<Id, String> recordTypeDeveloperNames = new Map<Id, String>();
    private static Integer lineCount = 0;

    private static Set<String> systemObjects = new Set<String>{
        'User', 'Profile', 'Group', 'UserRole', 'BusinessHours', 
        'Organization', 'EmailTemplate', 'Folder', 'Queue'
    };

    private static Set<String> excludedFields = new Set<String>{
        'OwnerId', 'CreatedById', 'CreatedDate', 'LastModifiedById', 'LastModifiedDate',
        'SystemModstamp', 'LastViewedDate', 'LastReferencedDate', 'IsDeleted',
        'ProfileId', 'UserRoleId'
    };
    
    private static void loadRecordTypeDeveloperNames(String objectType, Set<Id> recordTypeIds) {
        if(!recordTypeIds.isEmpty()) {
            for(RecordType rt : [SELECT Id, DeveloperName 
                               FROM RecordType 
                               WHERE Id IN :recordTypeIds 
                               AND SObjectType = :objectType]) {
                recordTypeDeveloperNames.put(rt.Id, rt.DeveloperName);
            }
        }
    }

    private static Boolean hasRecordTypes(String objectType) {
        try {
            Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectType).getDescribe();
            List<Schema.RecordTypeInfo> recordTypes = describe.getRecordTypeInfos();
            return !recordTypes.isEmpty() && recordTypes.size() > 1;
        } catch(Exception e) {
            return false;
        }
    }

    public static void generateTestDataWithLookups(List<Id> recordIds) {
        if(recordIds == null || recordIds.isEmpty()) {
            throw new TestDataGeneratorException('La liste d\'IDs ne peut pas être vide');
        }

        Map<String, Set<Id>> recordsByType = new Map<String, Set<Id>>();
        for(Id recordId : recordIds) {
            if(processedIds.contains(recordId)) continue;
            
            String objectType = recordId.getSObjectType().getDescribe().getName();
            if(!recordsByType.containsKey(objectType)) {
                recordsByType.put(objectType, new Set<Id>());
            }
            recordsByType.get(objectType).add(recordId);
            processedIds.add(recordId);
        }

        for(String objectType : recordsByType.keySet()) {
            processObjectRecords(objectType, new List<Id>(recordsByType.get(objectType)));
        }
    }

    private static Boolean isValidLookup(EntityParticle field) {
        if(field.DataType != 'Reference' || field.ReferenceTo == null) return false;
        String referenceTo = String.valueOf(field.ReferenceTo);
        
        for(String systemObj : systemObjects) {
            if(referenceTo.contains(systemObj)) return false;
        }
        return true;
    }

    private static Boolean isValidField(String fieldName, String fieldType) {
        if(fieldName == 'RecordTypeId') return true;
        
        if(excludedFields.contains(fieldName)) return false;
        if(fieldName.endsWith('__pc')) return false;
        if(fieldType == 'Formula') return false;
        
        return true;
    }

    private static List<String> filterFieldsList(List<String> fields, Set<String> fieldsWithValues) {
        List<String> filteredFields = new List<String>();
        for(String field : fields) {
            if(fieldsWithValues.contains(field)) {
                filteredFields.add(field);
            }
        }
        return filteredFields;
    }

    private static Set<String> findFieldsWithValues(List<SObject> records, List<String> queryFields) {
        Set<String> fieldsWithValues = new Set<String>();
        for(SObject record : records) {
            for(String fieldName : queryFields) {
                Object fieldValue = record.get(fieldName);
                if(fieldValue != null && String.isNotBlank(String.valueOf(fieldValue))) {
                    fieldsWithValues.add(fieldName);
                }
            }
        }
        return fieldsWithValues;
    }

    private static void processObjectRecords(String objectType, List<Id> recordIds) {
        Boolean hasRecordTypes = hasRecordTypes(objectType);

        List<EntityParticle> fieldMetadata = [
            SELECT QualifiedApiName, Length, DataType, ServiceDataTypeId, 
                   ValueTypeId, Precision, Scale, IsNillable, IsUpdatable,
                   IsCreatable, ReferenceTo
            FROM EntityParticle 
            WHERE EntityDefinitionId = :objectType
            ORDER BY QualifiedApiName ASC
        ];

        List<String> queryFields = new List<String>{'Id'};
        if(hasRecordTypes) {
            queryFields.add('RecordTypeId');
        }

        List<String> lookupFields = new List<String>();
        List<String> regularFields = new List<String>();
        Map<String, String> fieldTypeMap = new Map<String, String>();
        
        for(EntityParticle field : fieldMetadata) {
            if(!field.IsCreatable) continue;
            
            String fieldName = field.QualifiedApiName;
            String fieldType = field.DataType;
            
            if(fieldName == 'Id' || fieldName == 'RecordTypeId') continue;
            if(!isValidField(fieldName, fieldType)) continue;
            
            fieldTypeMap.put(fieldName, fieldType);
            
            if(isValidLookup(field)) {
                lookupFields.add(fieldName);
                queryFields.add(fieldName);
            } else if(fieldType != 'Reference') {
                regularFields.add(fieldName);
                queryFields.add(fieldName);
            }
        }

        String query = 'SELECT ' + String.join(queryFields, ', ') + 
                      ' FROM ' + objectType + ' WHERE Id IN :recordIds';
        List<SObject> records = Database.query(DataUtils.escapeSingleQuotes(query));

        if(!objectToUsedFieldsMap.containsKey(objectType)) {
            objectToUsedFieldsMap.put(objectType, new Set<String>());
            pendingInsertsByType.put(objectType, new List<SObjectTypeTestClasse__c>());
        }

        // Trouver les champs qui ont des valeurs
        Set<String> fieldsWithValues = findFieldsWithValues(records, queryFields);
        
        // Filtrer les listes de champs
        lookupFields = filterFieldsList(lookupFields, fieldsWithValues);
        regularFields = filterFieldsList(regularFields, fieldsWithValues);

        Set<Id> lookupIdsToProcess = new Set<Id>();
        Set<Id> recordTypeIds = new Set<Id>();
        
        if(hasRecordTypes) {
            for(SObject record : records) {
                Id recordTypeId = (Id)record.get('RecordTypeId');
                if(recordTypeId != null) {
                    recordTypeIds.add(recordTypeId);
                }
            }

            if(!recordTypeIds.isEmpty()) {
                loadRecordTypeDeveloperNames(objectType, recordTypeIds);
            }
        }
        
        for(SObject record : records) {
            if(!objectLineCounter.containsKey(objectType)) {
                objectLineCounter.put(objectType, 0);
            }
            objectLineCounter.put(objectType, objectLineCounter.get(objectType) + 1);
            
            String lineName = objectType + '_' + objectLineCounter.get(objectType);
            idToLineNameMap.put(record.Id, lineName);

            if(!objectHeaderCreated.containsKey(objectType)) {
                List<String> headerFields = new List<String>();
                if(hasRecordTypes && !recordTypeIds.isEmpty()) {
                    headerFields.add('RecordTypeId');
                }
                headerFields.addAll(lookupFields);
                headerFields.addAll(regularFields);
                createHeader(objectType, headerFields);
            }

            lineCount++;
            SObjectTypeTestClasse__c line = new SObjectTypeTestClasse__c(
                Name = lineName,
                SObjectType__c = objectType,
                lineType__c = 'line',
                LineOrder__c = lineCount + 1
            );

            Integer attributeIndex = 1;
            
            if(hasRecordTypes) {
                Id recordTypeId = (Id)record.get('RecordTypeId');
                if(recordTypeId != null) {
                    line.put('Attribute' + attributeIndex + '__c', recordTypeDeveloperNames.get(recordTypeId));
                    attributeIndex++;
                }
            }

            for(String fieldName : lookupFields) {
                if(attributeIndex > 18) break;
                processField(line, record, fieldName, attributeIndex, fieldTypeMap, lookupFields, lookupIdsToProcess, objectType);
                attributeIndex++;
            }
            
            for(String fieldName : regularFields) {
                if(attributeIndex > 18) break;
                processField(line, record, fieldName, attributeIndex, fieldTypeMap, lookupFields, lookupIdsToProcess, objectType);
                attributeIndex++;
            }
            
            pendingInsertsByType.get(objectType).add(line);
        }

        if(!lookupIdsToProcess.isEmpty()) {
            generateTestDataWithLookups(new List<Id>(lookupIdsToProcess));
        }
    }

    private static void createHeader(String objectType, List<String> fields) {
        SObjectTypeTestClasse__c header = new SObjectTypeTestClasse__c(
            Name = objectType + '_Header',
            SObjectType__c = objectType,
            lineType__c = 'header',
            LineOrder__c = 1
        );
        
        Integer attributeIndex = 1;
        for(String fieldName : fields) {
            if(attributeIndex > 18) break;
            String attributeField = 'Attribute' + attributeIndex + '__c';
            header.put(attributeField, fieldName);
            attributeIndex++;
        }
        
        pendingInsertsByType.get(objectType).add(header);
        objectHeaderCreated.put(objectType, true);
    }

    private static void processField(SObjectTypeTestClasse__c line, SObject record, String fieldName, 
                                   Integer attributeIndex, Map<String, String> fieldTypeMap, 
                                   List<String> lookupFields, Set<Id> lookupIdsToProcess, String objectType) {
        String attributeField = 'Attribute' + attributeIndex + '__c';
        Object fieldValue = record.get(fieldName);
        
        if(fieldValue != null) {
            String convertedValue = '';
            
            if(fieldValue instanceof Id) {
                Id recordId = (Id)fieldValue;
                String refObjectType = recordId.getSObjectType().getDescribe().getName();
                
                if(!processedIds.contains(recordId)) {
                    if(lookupFields.contains(fieldName)) {
                        lookupIdsToProcess.add(recordId);
                    }
                }
                
                if(idToLineNameMap.containsKey(recordId)) {
                    convertedValue = idToLineNameMap.get(recordId);
                } else {
                    if(!objectLineCounter.containsKey(refObjectType)) {
                        objectLineCounter.put(refObjectType, 0);
                    }
                    objectLineCounter.put(refObjectType, objectLineCounter.get(refObjectType) + 1);
                    convertedValue = refObjectType + '_' + objectLineCounter.get(refObjectType);
                    idToLineNameMap.put(recordId, convertedValue);
                }
            } else {
                convertedValue = convertFieldValue(fieldValue, fieldTypeMap.get(fieldName));
            }
            
            line.put(attributeField, convertedValue);
            objectToUsedFieldsMap.get(objectType).add(fieldName);
        } else {
            line.put(attributeField, '');
        }
    }

    private static String convertFieldValue(Object fieldValue, String fieldType) {
        if(fieldValue == null) return '';
        
        try {
            if(fieldType == 'Date') {
                Date dateVal = (Date)fieldValue;
                return DataUtils.getString(dateVal);
            } else if(fieldType == 'DateTime') {
                Datetime dtVal = (Datetime)fieldValue;
                return DataUtils.getString(dtVal);
            } else if(fieldType == 'Boolean') {
                Boolean boolVal = (Boolean)fieldValue;
                return String.valueOf(boolVal);
            } else if(fieldType == 'Currency' || fieldType == 'Double' || fieldType == 'Percent') {
                Decimal decVal = (Decimal)fieldValue;
                return String.valueOf(decVal);
            } else if(fieldType == 'Int') {
                Integer intVal = (Integer)fieldValue;
                return String.valueOf(intVal);
            }
            return String.valueOf(fieldValue);
        } catch(Exception e) {
            return String.valueOf(fieldValue);
        }
    }
    
    public static void commitRecords() {
        try {
            List<SObjectTypeTestClasse__c> allRecords = new List<SObjectTypeTestClasse__c>();
            
            List<String> objectTypes = new List<String>(pendingInsertsByType.keySet());
            objectTypes.sort();
            
            for(String objectType : objectTypes) {
                if(pendingInsertsByType.containsKey(objectType)) {
                    allRecords.addAll(pendingInsertsByType.get(objectType));
                }
            }
            
            if(!allRecords.isEmpty()) {
                insert allRecords;
                System.debug('Inserted ' + allRecords.size() + ' records in total');
            }
        } catch(Exception e) {
            throw new TestDataGeneratorException('Error committing records: ' + e.getMessage());
        } finally {
            resetAll();
        }
    }
    
    public static void resetAll() {
        processedIds.clear();
        objectHeaderCreated.clear();
        objectLineCounter.clear();
        idToLineNameMap.clear();
        pendingInsertsByType.clear();
        objectToUsedFieldsMap.clear();
        recordTypeDeveloperNames.clear();
        lineCount = 0;
    }
    
    public class TestDataGeneratorException extends Exception {}
}