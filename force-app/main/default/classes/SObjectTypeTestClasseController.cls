/**
 * Controller for the SObjectTypeTestClasse LWC
 */
public with sharing class SObjectTypeTestClasseController {
    
    /**
     * Gets all SObjectTypeTestClasse__c records with all attributes
     * @return List of SObjectTypeTestClasse__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<SObjectTypeTestClasse__c> getSObjectTypeTestClasses() {
        
            return [SELECT 
                    Id,
                    SObjectType__c,
                    Name, 
                    lineType__c,
                    LineOrder__c, 
                    Attribute1__c, 
                    Attribute2__c, 
                    Attribute3__c, 
                    Attribute4__c, 
                    Attribute5__c, 
                    Attribute6__c, 
                    Attribute7__c, 
                    Attribute8__c, 
                    Attribute9__c,
                    Attribute10__c, 
                    Attribute11__c, 
                    Attribute12__c, 
                    Attribute13__c, 
                    Attribute14__c, 
                    Attribute15__c, 
                    Attribute16__c, 
                    Attribute17__c, 
                    Attribute18__c, 
                    Attribute19__c,
                    Attribute20__c, 
                    Attribute21__c, 
                    Attribute22__c, 
                    Attribute23__c, 
                    Attribute24__c, 
                    Attribute25__c, 
                    Attribute26__c, 
                    Attribute27__c, 
                    Attribute28__c, 
                    Attribute29__c,
                    Attribute30__c, 
                    Attribute31__c, 
                    Attribute32__c, 
                    Attribute33__c, 
                    Attribute34__c, 
                    Attribute35__c, 
                    Attribute36__c, 
                    Attribute37__c, 
                    Attribute38__c, 
                    Attribute39__c,
                    Attribute40__c,
                    CreatedById, 
                    CreatedDate
                FROM SObjectTypeTestClasse__c
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ];
       
    }
    
    /**
     * Gets a specific SObjectTypeTestClasse__c record by Id
     * @param recordId The Id of the SObjectTypeTestClasse__c record
     * @return SObjectTypeTestClasse__c record
     */
    @AuraEnabled(cacheable=true)
    public static SObjectTypeTestClasse__c getSObjectTypeTestClasseById(Id recordId) {
        try {
            return [SELECT 
                    Id,
                    SObjectType__c,
                    Name, 
                    lineType__c,
                    LineOrder__c, 
                    Attribute1__c, 
                    Attribute2__c, 
                    Attribute3__c, 
                    Attribute4__c, 
                    Attribute5__c, 
                    Attribute6__c, 
                    Attribute7__c, 
                    Attribute8__c, 
                    Attribute9__c,
                    Attribute10__c, 
                    Attribute11__c, 
                    Attribute12__c, 
                    Attribute13__c, 
                    Attribute14__c, 
                    Attribute15__c, 
                    Attribute16__c, 
                    Attribute17__c, 
                    Attribute18__c, 
                    Attribute19__c,
                    Attribute20__c, 
                    Attribute21__c, 
                    Attribute22__c, 
                    Attribute23__c, 
                    Attribute24__c, 
                    Attribute25__c, 
                    Attribute26__c, 
                    Attribute27__c, 
                    Attribute28__c, 
                    Attribute29__c,
                    Attribute30__c, 
                    Attribute31__c, 
                    Attribute32__c, 
                    Attribute33__c, 
                    Attribute34__c, 
                    Attribute35__c, 
                    Attribute36__c, 
                    Attribute37__c, 
                    Attribute38__c, 
                    Attribute39__c,
                    Attribute40__c,
                    CreatedById, 
                    CreatedDate
                FROM SObjectTypeTestClasse__c
                WHERE Id = :recordId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving SObjectTypeTestClasse record: ' + e.getMessage());
        }
    }
     @AuraEnabled(cacheable=true)
    public static List<String> getTableHeaders() {
        List<String> headers = new List<String>();
        List<FieldDefinition> listAttribute = [SELECT id, DeveloperName, QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.DeveloperName = 'SObjectTypeTestClasse'];
        for(FieldDefinition field : listAttribute){
            if (field.QualifiedApiName.contains('Attribute'))  headers.add(field.QualifiedApiName);
        }
        return headers;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, SObjectTypeTestClasse__c> getHeaderRecords() {
        
            Map<String, SObjectTypeTestClasse__c> headerMap = new Map<String, SObjectTypeTestClasse__c>();
            
            List<SObjectTypeTestClasse__c> headerRecords = [
                SELECT 
                    Id, SObjectType__c, Name, lineType__c,
                    Attribute1__c, Attribute2__c, Attribute3__c, Attribute4__c, 
                    Attribute5__c, Attribute6__c, Attribute7__c, Attribute8__c, 
                    Attribute9__c, Attribute10__c, Attribute11__c, Attribute12__c, 
                    Attribute13__c, Attribute14__c, Attribute15__c, Attribute16__c, 
                    Attribute17__c, Attribute18__c, Attribute19__c, Attribute20__c,
                    Attribute21__c, Attribute22__c, Attribute23__c, Attribute24__c, 
                    Attribute25__c, Attribute26__c, Attribute27__c, Attribute28__c, 
                    Attribute29__c, Attribute30__c, Attribute31__c, Attribute32__c,
                    Attribute33__c, Attribute34__c, Attribute35__c, Attribute36__c, 
                    Attribute37__c, Attribute38__c, Attribute39__c, Attribute40__c
                FROM SObjectTypeTestClasse__c
                WHERE lineType__c = 'header'
                WITH SECURITY_ENFORCED
            ];
            
            for (SObjectTypeTestClasse__c header : headerRecords) {
                headerMap.put(header.SObjectType__c, header);
            }
            
            return headerMap;
       
    }  
    
    /**
     * Gets data for CSV export with a subset of fields
     * @return List of SObjectTypeTestClasse__c records with selected fields for export
     */
    @AuraEnabled(cacheable=true)
    public static List<SObjectTypeTestClasse__c> getDataForExport() {
      
            return [SELECT 
                    Name,
                    SObjectType__c,
                    lineType__c,
                    LineOrder__c,
                    Attribute1__c,
                    Attribute2__c,
                    Attribute3__c,
                    Attribute4__c,
                    Attribute5__c,
                    Attribute6__c,
                    Attribute7__c,
                    Attribute8__c,
                    Attribute9__c,
                    Attribute10__c,
                    Attribute11__c,
                    Attribute12__c,
                    Attribute13__c,
                    Attribute14__c,
                    Attribute15__c,
                    Attribute16__c,
                    Attribute17__c,
                    Attribute18__c
                FROM SObjectTypeTestClasse__c
                WITH SECURITY_ENFORCED
                ORDER BY Name ASC
            ];
        
    }
}