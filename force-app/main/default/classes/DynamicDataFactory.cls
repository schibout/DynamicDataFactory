/**
 * @description       : 
 * @author            : samir.chibout.ext@sodexo.com
 * @group             : 
 * @last modified on  : 18-01-2023
 * @last modified by  : samir.chibout.ext@sodexo.com
**/
public with sharing class DynamicDataFactory {
    
    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();
    List<SObjectTypeTestClasse__c> globalSObjectTypeTestClasseList ;
    static Map<String, SObjectTypeTestClasse__c> globalSObjectTypeFieldNameMap = new Map<String, SObjectTypeTestClasse__c>() ;
    static Map<String, SObjectTypeTestClasse__c> globalSObjectTypeDataMap  = new Map<String, SObjectTypeTestClasse__c>() ;
    Map<String,SObject> globalSObjectAllredayCreateMap = new Map<String,SObject>();
    Map<String,String> globalRecordTypeIdsMap ;
    Integer maxNumberAttribute = 0 ;
    String  globalOrderByAttribute ;
    public DynamicDataFactory() {

        List<FieldDefinition> filedList = getFiledList();  
        String strQuery = 'SELECT Id,Name,SObjectType__c,lineType__c,LineOrder__c';
        strQuery = strQuery + getFildNames(filedList,'Attribute') +' FROM SObjectTypeTestClasse__c ' ;
        globalSObjectTypeTestClasseList = (List<SObjectTypeTestClasse__c> ) Database.query(DataUtils.escapeSingleQuotes(strQuery)); 
        for (SObjectTypeTestClasse__c var : globalSObjectTypeTestClasseList) {
            if ('header'.equalsIgnoreCase(var.lineType__c))  globalSObjectTypeFieldNameMap.put(var.SObjectType__c,var);
            if ('line'.equalsIgnoreCase(var.lineType__c))  globalSObjectTypeDataMap.put(var.name,var);
        } 
        globalRecordTypeIdsMap = getRecordTypeDataMap(globalSObjectTypeTestClasseList);                            
    }

    public List<SObject> createSobjectsCascadeLookup(String sobjectType) {
        return createSobjects(sobjectType,null,true);
    }

    public List<SObject> createSobjects(String sobjectType,Boolean cascadeLookup) {
        return createSobjects(sobjectType,null,cascadeLookup);
    } 

    public List<SObject> createSobjects(String sobjectType) {
        return createSobjects(sobjectType,null,false);
    }
    public List<SObject> createSobjectsWithSpecificName(String sobjectType,String  sObjectRecordName) {
        return createSobjects(sobjectType, sObjectRecordName,false);
    } 

    public List<SObject> createSobjectsWithSpecificNameCascadeLookup(String sobjectType,String  sObjectRecordName) {
        return createSobjects(sobjectType, sObjectRecordName,true);
    }

    public Map<String, SObjectTypeTestClasse__c> getGlobalSObjectTypeFieldNameMap() {
        return globalSObjectTypeFieldNameMap ;
    }
    private List<FieldDefinition> getFiledList() {
        List<FieldDefinition> listOfAttribute = [SELECT id ,DeveloperName , QualifiedApiName FROM FieldDefinition 
                                                WHERE EntityDefinition.DeveloperName ='SObjectTypeTestClasse'];  
        return listOfAttribute;
    }

    private String getFildNames(List<FieldDefinition> listField, String fieldNameCompare) {
        String retVal = '' ;
        for (FieldDefinition var : listField) {
            
            String field = var.DeveloperName ;
            if (field.containsIgnoreCase(fieldNameCompare)) {
                retVal =retVal+','+var.QualifiedApiName;
                if (fieldNameCompare =='Attribute') {
                    maxNumberAttribute++;
                    //globalOrderByAttribute+='Attribute'+maxNumberAttribute+'__c NULL FIRST ';
                }   
            }  
            //globalOrderByAttribute +=' ORDER BY '+ globalOrderByAttribute+ ' , SObjectType__c';  
        }
        return retVal ;
    }
    public Sobject getSingleSobjectFromBuilder(ObjectAndFieldBuilder sobjectBuilder) {
        loadAttributeData(sobjectBuilder);
        System.debug('getSingleObject '+sobjectBuilder.sObjectToCreate);
        return sobjectBuilder.sObjectToCreate ;
    }
    
    public SObject getSobject(String sobjectType,String  sObjectRecordName) {
        List<SobjectToCreateWrapper> attributeList =getAttribute(sobjectType);
        if (attributeList.size() == 0 )throw new DynamicDataFactoryException('No Data Found for this SObject');
        List<SObject> sObjectListToCreate = new List<SObject>();
        List<SObject> sObjectList = new List<SObject>();
        for (SobjectToCreateWrapper sobjectToCreate : attributeList) {
            SObjectTypeTestClasse__c var = sobjectToCreate.sObjectTypeTestClasse ;
            if (!checkCondition( sObjectRecordName,var)) continue ;
            SObject objetAllreadyCreated = sObjectRecordName==null ? globalSObjectAllredayCreateMap.get(var.Name):globalSObjectAllredayCreateMap.get(sObjectRecordName);
            if (objetAllreadyCreated == null ) {
                ObjectAndFieldBuilder  builder = initializeBuilder(sobjectType, var);
                builder.setCascadeLookup(false);
                SObject  sobj = getSingleSobjectFromBuilder(builder);
                if (sobj == null ) throw new DynamicDataFactoryException('can not create an SObject');
                System.debug('Sobject '+var.Name+' '+sobj);
                return  sobj ;
            }else {
                return (objetAllreadyCreated);
            }
        }
        return (null);
    }
    private Map<String,String> getRecordTypeDataMap(List<SObjectTypeTestClasse__c> dataList) {
        Map<String, String> mapName = new Map<String, String>();                                                    
        Map<String,String> fieldWithRecordTypeMap = getFiledNamedWithWithRecordTypeMap(dataList);
        System.debug(JSON.serializePretty(fieldWithRecordTypeMap));                                        
        if (fieldWithRecordTypeMap.size() == 0) return mapName ;
        Map<String,String> sObjectRecordTypeValueMap = new Map<String,String>();
        for (SObjectTypeTestClasse__c data : dataList) {
            String attributefieldName =fieldWithRecordTypeMap.get(data.SObjectType__c);
            if (data.lineType__c !='line' || attributefieldName == null ) continue ;
            for (String fieldName : fieldWithRecordTypeMap.values()) {
                    String fieldvalue =(String)data.get(fieldName);
                    if (fieldvalue !=null){
                        sObjectRecordTypeValueMap.put(fieldvalue,data.SObjectType__c);
                    }    
            }
        }
        System.debug(JSON.serializePretty(sObjectRecordTypeValueMap));
        if (sObjectRecordTypeValueMap.size() == 0 ) return mapName ;
        for (recordType rcd : [SELECT Id, DeveloperName,SobjectType  
                               FROM RecordType WHERE SobjectType IN :sObjectRecordTypeValueMap.values() 
                               AND DeveloperName IN :sObjectRecordTypeValueMap.keySet()]) {
                                mapName.put(rcd.DeveloperName, rcd.id);
        }
        return mapName ;
    }

    private  Map<String,String>  getFiledNamedWithWithRecordTypeMap(List<SObjectTypeTestClasse__c> dataList) {
        List<FieldDefinition> listOfAttribute = [SELECT id ,DeveloperName , QualifiedApiName FROM FieldDefinition 
                                                WHERE EntityDefinition.DeveloperName ='SObjectTypeTestClasse'];
        Map<String,String> fieldWithRecordTypeMap = new Map<String,String>();                                        
        for (SObjectTypeTestClasse__c data : dataList) {
            if (!(data.lineType__c =='header')) continue; 
            for (FieldDefinition fieldvar : listOfAttribute) {
                if (notCheckConditionOnFieldDefinition(fieldvar)) continue;
                String namefield = (String)data.get(fieldvar.QualifiedApiName);
                if(namefield !=null && namefield.containsIgnoreCase('recordType') )  
                fieldWithRecordTypeMap.put(data.SObjectType__c,fieldvar.QualifiedApiName);
            }
        }
        System.debug(JSON.serialize(fieldWithRecordTypeMap) );
        return fieldWithRecordTypeMap ;
    }

    public boolean notCheckConditionOnFieldDefinition(FieldDefinition fieldvar){
        return !(checkConditionOnFieldDefinition(fieldvar));
    }
    public boolean checkConditionOnFieldDefinition(FieldDefinition fieldvar){
        String developerName = fieldvar.DeveloperName ;
        String qualifiedApiName = fieldvar.QualifiedApiName ;
        if (!(developerName.containsIgnoreCase('Attribute'))) return false;
        return true ;
    }
    private List<SObject> createSobjects(String sobjectType,String  sObjectRecordName,Boolean cascadeLookup) {
        List<SobjectToCreateWrapper> attributeList =getAttribute(sobjectType);
        if (attributeList.size() == 0 )throw new DynamicDataFactoryException('No Data Found for this SObject');
        List<SObject> sObjectListToCreate = new List<SObject>();
        List<SObject> sObjectList = new List<SObject>();
        for (SobjectToCreateWrapper sobjectToCreate : attributeList) {
            SObjectTypeTestClasse__c var = sobjectToCreate.sObjectTypeTestClasse ;
            if (!checkCondition( sObjectRecordName,var)) continue ;
            SObject objetAllreadyCreated = sObjectRecordName==null ? globalSObjectAllredayCreateMap.get(var.Name):globalSObjectAllredayCreateMap.get(sObjectRecordName);
            if (objetAllreadyCreated == null ) {
                ObjectAndFieldBuilder  builder = initializeBuilder(sobjectType, var);
                builder.setCascadeLookup(cascadeLookup);
                SObject  sobj = getSingleSobjectFromBuilder(builder);
                if (sobj == null ) throw new DynamicDataFactoryException('can not create an SObject');
                sObjectListToCreate.add(sobj) ; 
                globalSObjectAllredayCreateMap.put(var.Name , sobj);  
                System.debug('Sobject '+var.Name+' '+sobj);
            }else {
                System.debug('objetAllreadyCreated '+var.Name+' '+objetAllreadyCreated);
                sObjectList.add(objetAllreadyCreated);
            }
        }
        if (sObjectListToCreate.size() > 0 ){
            System.debug('sObjectListToCreate '+sObjectListToCreate);
            Database.insert(sObjectListToCreate, true);
            sObjectList.addAll(sObjectListToCreate);
        } 
        return (sObjectList);
    }
    
    private ObjectAndFieldBuilder initializeBuilder(String sobjectType,SObjectTypeTestClasse__c var){
        ObjectAndFieldBuilder builder = new ObjectAndFieldBuilder(sobjectType,var);
        builder.initializeSObject();
        return builder ;
    }
    private Boolean checkCondition(String dname,SObjectTypeTestClasse__c var ) {
        if (DataUtils.isNull(dname) ) return true ;
        if (DataUtils.isNotNull(dname) && dname.equalsIgnoreCase(var.name)) return true ;
        return false ;
    }
    
    private void loadAttributeData(ObjectAndFieldBuilder builder ){
        for (Integer i = 1; i < maxNumberAttribute; i++) {
            String fieldName = 'Attribute'+i+'__c';
            String fieldValue = (String)builder.fieldNameList.get(fieldName);
            if (fieldValue == null ) continue ;
            try {
                Schema.DescribeFieldResult fieldDescribe =builder.fieldMap.get(fieldValue).getDescribe() ;    
                builder.sObjectToCreate = putAttributeValue(builder,fieldDescribe,builder.fieldValueList.get(fieldName)) ;
            } catch (Exception ex) {
                throw new DynamicDataFactoryException('Field Name '+fieldValue+' Does not exists in SobjectType '+builder.sObjectTypeName +'  '+ex.getMessage()+'\n');
            }
        }
    }
    private SObject putReferenceValue(ObjectAndFieldBuilder builder,Schema.DescribeFieldResult fieldDescribe,Object objVal) {
        System.debug('Type '+fieldDescribe.getType());
        System.debug('Reference '+fieldDescribe.getReferenceTo());
        Schema.DisplayType fieldType = fieldDescribe.getType() ;
        if ('recordTypeId'.equalsIgnoreCase(fieldDescribe.getName()) ) return (putRecordTypeValue(builder,fieldDescribe,objVal)); 
        if (fieldType != Schema.DisplayType.Reference ) return (putAttributeValue(builder,fieldDescribe,objVal)); 
        if ((fieldDescribe.getType() != Schema.DisplayType.Reference) ) return builder.sObjectToCreate ;
        SObject refVal= globalSObjectAllredayCreateMap.get((String)objVal);
        if (refVal == null && objVal != null ) {
            String referenceObjectType = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
            List<SObject> referenceList = createSobjects(referenceObjectType,(String)objVal,builder.cascadeLookup);  
            System.debug('referenceList '+ referenceList);  
            if (referenceList.size() > 0 ) {
                refVal = globalSObjectAllredayCreateMap.get((String)objVal) ;
            }
        }
        if (refVal != null )builder.sObjectToCreate.put(fieldDescribe.getName(),refVal.Id );
        return builder.sObjectToCreate ;
    }
    private  Sobject putRecordTypeValue (ObjectAndFieldBuilder builder,Schema.DescribeFieldResult fieldDescribe,Object objVal) {
        Schema.DisplayType fieldType = fieldDescribe.getType() ;
        if (!('RecordTypeId'.equalsIgnoreCase(fieldDescribe.getName() ) ) || objVal ==null) return builder.sObjectToCreate ;
        String recordTypeId = globalRecordTypeIdsMap.get((String)objVal);
        if (recordTypeId != null) builder.sObjectToCreate.put(fieldDescribe.getName(),recordTypeId) ;
        return builder.sObjectToCreate ;
    } 
    private  Sobject putAttributeValue (ObjectAndFieldBuilder builder,Schema.DescribeFieldResult fieldDescribe,Object objVal) {
        Schema.DisplayType fieldType = fieldDescribe.getType() ;
        if (fieldDescribe.getName() =='RecordTypeId' ) return (putRecordTypeValue(builder,fieldDescribe,objVal)); 
        if (fieldType == Schema.DisplayType.Reference && builder.getCascadeLookup()) return (putReferenceValue(builder,fieldDescribe,objVal)); 
        if (fieldType == Schema.DisplayType.Reference && fieldDescribe.getName() !='RecordTypeId' ) return builder.sObjectToCreate ;
        if ( !(fieldDescribe.isCreateable() && fieldDescribe.isUpdateable()) ) return builder.sObjectToCreate ;
        if (fieldType == Schema.DisplayType.Integer) {
            builder.sObjectToCreate.put(fieldDescribe.getName() ,getInteger(objVal));
        }else if (fieldType ==Schema.DisplayType.Double) {
            builder.sObjectToCreate.put(fieldDescribe.getName(),getDouble(objVal));
        }else if (fieldType ==Schema.DisplayType.Currency) {
            builder.sObjectToCreate.put(fieldDescribe.getName(),getDouble(objVal));
        }else if (fieldType ==Schema.DisplayType.PERCENT) {
            builder.sObjectToCreate.put(fieldDescribe.getName(),getDouble(objVal));
        }else if (fieldType ==Schema.DisplayType.Date) {
            builder.sObjectToCreate.put(fieldDescribe.getName(),getDate(objVal));
        }else if (fieldType ==Schema.DisplayType.DateTime) {
            builder.sObjectToCreate.put(fieldDescribe.getName(),getDateTime(objVal));
        } else if (fieldType == Schema.DisplayType.Boolean) {
            builder.sObjectToCreate.put(fieldDescribe.getName(), getBoolean(objVal));
        } else {
            builder.sObjectToCreate.put(fieldDescribe.getName(),objVal) ;
        }
       return builder.sObjectToCreate ; 
    }
    
    private  Map<String, Schema.SObjectField> getFields (String sobjectTypeName) {
        Map<String, Schema.SObjectField> fieldMap = GLOBAL_DESCRIBE.get(sobjectTypeName).getDescribe().fields.getMap();
        return fieldMap ;
    }
    private static Date getDate(Object objVal) {
        System.debug('getDate '+objVal);
        if (objVal ==null) return Date.today();
        String strDate = DataUtils.getStringValue(objVal);
        if (strDate.equalsIgnoreCase('today') ) return Date.today();
        if (strDate.startsWith('today') && strDate.indexOf(':') > 0)  {
            return Date.today().addDays((Integer.valueOf(strDate.substring(strDate.indexOf(':')+1))));
        } 
        Date returnDate ;
       try {
        returnDate = Date.valueOf(strDate);
       }catch (IllegalArgumentException  ex) {
        System.debug('Can not parse Date: ' + strDate + '. Error: ' + ex.getMessage());
        throw new DynamicDataFactoryException('Invalid date format: ' + strDate);
       }
       return returnDate ;
    }
    private static Datetime getDateTime(Object strDate) {
        if (strDate ==null) return DateTime.now();
        DateTime returnDate ;
       try {
        returnDate = DateTime.parse((String)strDate);
       }catch (Exception ex) {
        System.debug('Can not parse Date '+strDate);
        returnDate = DateTime.now();
       }
       return returnDate ;
    }
    private static Integer getInteger(Object obj) {
        if (obj == null ) return null ;
        Integer valReturn ;
        try {
                valReturn = Integer.valueOf(obj);
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return valReturn ;
    }

    private static Boolean getBoolean(Object obj) {
        if (obj == null ) return null ;
        Boolean valReturn ;
        try {
                valReturn = 'true'.equalsIgnoreCase((String)obj) ? true : false;
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return valReturn ;
    }

    private static Decimal getDouble(Object obj) {
        if (obj == null ) return null ;
        Decimal valReturn ;
        try {
                valReturn = Decimal.valueOf((String)obj);
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return valReturn ;
    }

    private List<SobjectToCreateWrapper> getAttribute(String sObjectType) {
        List<SobjectToCreateWrapper> attributeList = new List<SobjectToCreateWrapper>();
        for (SObjectTypeTestClasse__c var : globalSObjectTypeTestClasseList) {
            if (var.SObjectType__c ==sObjectType && var.lineType__c =='line') attributeList.add(new SobjectToCreateWrapper(var));
        }
        return attributeList ;
    }

    public class SobjectToCreateWrapper implements Comparable{
        SObjectTypeTestClasse__c sObjectTypeTestClasse;
        private SobjectToCreateWrapper (SObjectTypeTestClasse__c sObjectTypeTestClasse) {
            this.sObjectTypeTestClasse = sObjectTypeTestClasse ;
        }
        public Integer compareTo(Object compareTo) {
            SObjectTypeTestClasse__c compareToEmp = (SObjectTypeTestClasse__c)compareTo;
            if (this.sObjectTypeTestClasse.LineOrder__c == compareToEmp.LineOrder__c) return 0;
            if (this.sObjectTypeTestClasse.LineOrder__c > compareToEmp.LineOrder__c) return 1;
            return -1;        
        }
    }
    class ObjectAndFieldBuilder {
        Map<String, Schema.SObjectField> fieldMap ;
        SObjectTypeTestClasse__c fieldNameList ;
        SObjectTypeTestClasse__c fieldValueList ;
        Boolean cascadeLookup ;
        String   sObjectRecordName ;
        String   sObjectTypeName ;
        SObject  sObjectToCreate ;
        public ObjectAndFieldBuilder (String sObjectTypeName, SObjectTypeTestClasse__c fieldValueList) {
            this.sObjectTypeName = sObjectTypeName ;
            this.fieldValueList = fieldValueList ;
            this.sObjectRecordName = (String)fieldValueList.get('Name');
            this.fieldNameList = globalSObjectTypeFieldNameMap.get(sObjectTypeName); 
            this.fieldMap = getFields(this.sObjectTypeName);
        }
        private void initializeSObject() {
            Schema.sObjectType token = GLOBAL_DESCRIBE.get(this.sObjectTypeName);
            SObject sObjectToCreate = token.newSObject();
            this.sObjectToCreate = sObjectToCreate ;
        }
        private void setCascadeLookup(Boolean cascadeLookup) {
            this.cascadeLookup = cascadeLookup ;
        }
        private Boolean getCascadeLookup() {
            return this.cascadeLookup ;
        }
        private  Map<String, Schema.SObjectField> getFields (String sobjectTypeName) {
            Map<String, Schema.SObjectField> fieldMap = GLOBAL_DESCRIBE.get(sobjectTypeName).getDescribe().fields.getMap();
            return fieldMap ;
        }
    }

    public static User createGestionUser() {
       // Create a user for the test
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Gestion 1D Customer Community' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;

        // Assign the Gestion1D User permission set
        PermissionSet gestion1DPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Gestion1DCommunityUser' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = gestion1DPermissionSet.Id
        );
        insert psa;
        return testUser;
    }
    class DynamicDataFactoryException extends Exception {}

}