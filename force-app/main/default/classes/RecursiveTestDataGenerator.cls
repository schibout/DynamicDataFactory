public with sharing class RecursiveTestDataGenerator {
    
    private static Set<String> processedIds = new Set<String>();
    private static Map<String, Boolean> objectHeaderCreated = new Map<String, Boolean>();
    private static Map<String, Integer> objectLineCounter = new Map<String, Integer>();
    private static Map<Id, String> idToLineNameMap = new Map<Id, String>();
    private static Map<String, List<SObjectTypeTestClasse__c>> pendingInsertsByType = new Map<String, List<SObjectTypeTestClasse__c>>();
    private static Map<String, Set<String>> objectToUsedFieldsMap = new Map<String, Set<String>>();
    private static Map<String, List<Map<String, String>>> objectToDataMap = new Map<String, List<Map<String, String>>>();
    private static Integer lineCount = 0;
    private static Set<String> systemUserFields = new Set<String>{
        'OwnerId', 'CreatedById', 'LastModifiedById'
    };
    
    public static void generateTestDataWithLookups(Id recordId) {
        if (!Schema.SObjectType.SObjectTypeTestClasse__c.isCreateable()) {
            throw new TestDataGeneratorException('L\'utilisateur n\'a pas les droits de création sur SObjectTypeTestClasse__c');
        }

        if(processedIds.contains(recordId)) {
            return;
        }
        processedIds.add(recordId);
        
        String objectName = DataUtils.getSobjectNameById(recordId);
        System.debug('Processing object: ' + objectName);
        
        // Initialiser les collections pour cet objet
        if (!objectToUsedFieldsMap.containsKey(objectName)) {
            objectToUsedFieldsMap.put(objectName, new Set<String>());
            objectToDataMap.put(objectName, new List<Map<String, String>>());
        }
        
        if (!objectLineCounter.containsKey(objectName)) {
            objectLineCounter.put(objectName, 0);
        }
        objectLineCounter.put(objectName, objectLineCounter.get(objectName) + 1);
        
        String lineName = objectName + '_' + objectLineCounter.get(objectName);
        idToLineNameMap.put(recordId, lineName);
        
        // Récupérer les métadonnées des champs
        List<EntityParticle> fieldMetadata = [
            SELECT QualifiedApiName, Length, DataType, ServiceDataTypeId, 
                   ValueTypeId, Precision, Scale, IsNillable, IsUpdatable,
                   IsCreatable, ReferenceTo
            FROM EntityParticle 
            WHERE EntityDefinitionId = :objectName
            ORDER BY QualifiedApiName ASC
        ];

        // Séparer les champs en lookups et non-lookups
        List<String> lookupFields = new List<String>();
        List<String> regularFields = new List<String>();
        Map<String, String> fieldTypeMap = new Map<String, String>();
        
        for(EntityParticle field : fieldMetadata) {
            if(!field.IsCreatable) continue;
            
            String fieldName = field.QualifiedApiName;
            fieldTypeMap.put(fieldName, field.DataType);
            
            if(systemUserFields.contains(fieldName)) continue;
            
            if(field.DataType == 'Reference' && 
               field.ReferenceTo != null && 
               String.valueOf(field.ReferenceTo) != 'RecordType' &&
               !String.valueOf(field.ReferenceTo).contains('User')) {
                lookupFields.add(fieldName);
            } else {
                regularFields.add(fieldName);
            }
        }

        List<String> orderedFields = new List<String>();
        orderedFields.addAll(lookupFields);
        orderedFields.addAll(regularFields);
        
        String query = 'SELECT ' + String.join(orderedFields, ', ') + 
                      ' FROM ' + objectName + ' WHERE Id = :recordId';
        SObject record = Database.query(DataUtils.escapeSingleQuotes(query));
        
        // Collecter les données pour cette ligne
        Map<String, String> rowData = new Map<String, String>();
        
        for(String fieldName : orderedFields) {
            Object fieldValue = record.get(fieldName);
            String convertedValue = '';
            
            if(fieldValue != null) {
                try {
                    String fieldType = fieldTypeMap.get(fieldName);
                    if(lookupFields.contains(fieldName) && fieldValue instanceof Id) {
                        Id lookupId = (Id)fieldValue;
                        if(!processedIds.contains(lookupId)) {
                            generateTestDataWithLookups(lookupId);
                        }
                        convertedValue = idToLineNameMap.get(lookupId);
                    } else if(fieldType == 'Date') {
                        Date dateVal = (Date)fieldValue;
                        convertedValue = DataUtils.getString(dateVal);
                    } else if(fieldType == 'DateTime') {
                        Datetime dtVal = (Datetime)fieldValue;
                        convertedValue = DataUtils.getString(dtVal);
                    } else if(fieldType == 'Boolean') {
                        Boolean boolVal = (Boolean)fieldValue;
                        convertedValue = String.valueOf(boolVal);
                    } else if(fieldType == 'Currency' || fieldType == 'Double' || fieldType == 'Percent') {
                        Decimal decVal = (Decimal)fieldValue;
                        convertedValue = String.valueOf(decVal);
                    } else if(fieldType == 'Int') {
                        Integer intVal = (Integer)fieldValue;
                        convertedValue = String.valueOf(intVal);
                    } else {
                        convertedValue = String.valueOf(fieldValue);
                    }
                    
                    if(String.isNotBlank(convertedValue)) {
                        objectToUsedFieldsMap.get(objectName).add(fieldName);
                        rowData.put(fieldName, convertedValue);
                    }
                } catch(Exception e) {
                    System.debug('Erreur de conversion pour le champ ' + fieldName + ': ' + e.getMessage());
                }
            }
        }
        
        objectToDataMap.get(objectName).add(rowData);
    }
    
    public static void commitRecords() {
        try {
            List<SObjectTypeTestClasse__c> allRecords = new List<SObjectTypeTestClasse__c>();
            
            List<String> objectTypes = new List<String>(objectToDataMap.keySet());
            objectTypes.sort();
            
            for(String objectType : objectTypes) {
                Set<String> usedFields = objectToUsedFieldsMap.get(objectType);
                List<Map<String, String>> dataRows = objectToDataMap.get(objectType);
                
                if(usedFields.isEmpty() || dataRows.isEmpty()) continue;
                
                // Créer le header avec uniquement les champs utilisés
                List<String> orderedUsedFields = new List<String>(usedFields);
                orderedUsedFields.sort();
                
                SObjectTypeTestClasse__c header = new SObjectTypeTestClasse__c(
                    Name = objectType + '_Header',
                    SObjectType__c = objectType,
                    lineType__c = 'header',
                    LineOrder__c = 1
                );
                
                Integer attributeIndex = 1;
                for(String fieldName : orderedUsedFields) {
                    if(attributeIndex > 18) break;
                    String attributeField = 'Attribute' + attributeIndex + '__c';
                    header.put(attributeField, fieldName);
                    attributeIndex++;
                }
                
                allRecords.add(header);
                
                // Créer les lignes de données
                Integer lineNumber = 1;
                for(Map<String, String> rowData : dataRows) {
                    SObjectTypeTestClasse__c line = new SObjectTypeTestClasse__c(
                        Name = objectType + '_' + lineNumber,
                        SObjectType__c = objectType,
                        lineType__c = 'line',
                        LineOrder__c = lineNumber + 1
                    );
                    
                    attributeIndex = 1;
                    for(String fieldName : orderedUsedFields) {
                        if(attributeIndex > 18) break;
                        String attributeField = 'Attribute' + attributeIndex + '__c';
                        line.put(attributeField, rowData.get(fieldName) != null ? rowData.get(fieldName) : '');
                        attributeIndex++;
                    }
                    
                    allRecords.add(line);
                    lineNumber++;
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
        objectToUsedFieldsMap.clear();
        objectToDataMap.clear();
        lineCount = 0;
    }
    
    public class TestDataGeneratorException extends Exception {}
}