/**
* @description       : 
* @author            : samir.chibout.ext@sodexo.com
* @group             : 
* @last modified on  : 26-01-2023
* @last modified by  : samir.chibout.ext@sodexo.com
**/
public with sharing class DataUtils {
    
    public static Boolean isRunning = false ;
    
    
/**
* 
* @param  sObjectName Adresse__c
* Exemple Adresse__c retourne Adresse
*/
    public static String getOriginalName(String sObjectName) {
        if (sObjectName.toLowerCase().endsWith('__c')) {
            Integer index = sObjectName.toLowerCase().indexOf('__c');
            return (sObjectName.substring(0, index));
        }
        return sObjectName ;  
    }
     public static Integer getInteger(Object obj) {
        if (obj == null ) return null ;
        Integer valReturn ;
        try {
            valReturn = Integer.valueOf(obj);
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return valReturn ;
    }
    

    public static String getStringValue(Object obj) {
        return obj != null ? String.valueOf(obj) : null ;  
    }
    
    public static String getString(Object obj) {
        String jsonData ;
        try {
            if ( obj instanceOf String ) { 
                jsonData = (String) obj; 
            } else  {
                jsonData = JSON.serialize(obj, true);
            } 
        } catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return jsonData ;
    }
    
    public static Boolean getBoolean(Object obj) {
        if (obj == null ) return null ;
        Boolean valReturn ;
        try {
            valReturn = Boolean.valueOf(obj);
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
           return null;
        }
        return valReturn ;
    }
    
    public static Decimal getDouble(Object obj) {
        if (obj == null ) return null ;
        Decimal valReturn ;
        try {
            valReturn = Decimal.valueOf((String)obj);
        }catch (Exception e) {
            System.debug('Erreur on '+obj+' Message ='+e.getCause());
        }
        return valReturn ;
    }
    
    public static String escapeSingleQuotes(String queryString) {
        return String.escapeSingleQuotes(queryString);
    }
    
    public static  Map<String, Schema.SObjectField> getFieldsMap (String sobjectTypeName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = globalDescribe.get(sobjectTypeName).getDescribe().fields.getMap();
        return fieldMap ;
    }
    public static Boolean isNotNull(String str) {
        return !isNull(str);
    }
/**
* Verifie si une valeur est nulle ou '' ou '   '   
*/
    public static Boolean isNull (String str) {
        if (str ==null ||String.isEmpty(str)||String.isBlank(str)||str.trim().length() == 0) return true ;
        return false ;
    }
/**
* @param objectId 
* @return Name of SobjectType
*/
    public static String getSobjectNameById(Id objectId) {
        if (objectId == null) return null ;
        try {
            return (objectId.getSobjectType().getDescribe().getName());    
        } catch (Exception exp) {
            System.debug('Can not fin object name ');
        }
        return null ;
    }
/**
* 
* @param recordName 
* @return Name of SobjectType
*/
    public static String getSobjectNameByRecord(SObject recordName) {
        if (recordName == null) return null ;
        return (recordName.Id.getSobjectType().getDescribe().getName());
    }
    
   
    public static String getRecordTypeDeveloperNameByRecord(SObject sobj)
    {   try {
        if (sobj ==null ) return null ;
        Id recordTypeId = (Id)sobj.get('recordTypeId') ;
        if (isNull(recordTypeId)) return null ;
        String sObjectName = getSobjectNameByRecord(sobj);
        String valReturn = getRecordTypeDeveloperNameById(sObjectName,recordTypeId);
        return valReturn;
    } catch (Exception ex) {
        System.debug('No RecordType found in this Object '+ ex.getMessage());    
    }
     return null ;
    } 
    
    public static String getRecordTypeDeveloperNameById(String objectName, String recordTypeId)
    {
        return getRecordTypeDeveloperNameById(objectName,(Id)recordTypeId);
    } 
    
    public static Map < String, Sobject > generateMapStringSObjects(List < Sobject > listOfData, String criteria) {
        Map <String, Sobject> resultMap = new Map <String, Sobject> ();
        
        for (Sobject item: listOfData) {
                resultMap.put((String) item.get(criteria), item);
        }
        return resultMap;
    }

    public static Map < Id, List < Sobject >> generateMapIdListOfObjects(List < Sobject > listOfData, String criteria) {
        Map <Id, List < Sobject >> resultMap = new Map < Id, List < Sobject >> ();
        
        for (Sobject item: listOfData) {
            
            if (resultMap.containsKey((String) item.get(criteria))) {
                resultMap.get((String) item.get(criteria)).add(item);
            }else {
                List < Sobject > groupedList = new List < Sobject > ();
                groupedList.add(item);
                resultMap.put((String) item.get(criteria), groupedList);
            }
        }
        return resultMap;
    }
    
    public static Map < Id, Set < Sobject >> generateMapIdSetOfObjects(List < Sobject > listOfData, String criteria) {
        Map <Id, Set < Sobject >> resultMap = new Map < Id, Set < Sobject >> ();
        
        for (Sobject item: listOfData) {
            
            if (resultMap.containsKey((String) item.get(criteria))) {
                resultMap.get((String) item.get(criteria)).add(item);
            }else {
                Set < Sobject > groupedList = new Set < Sobject > ();
                groupedList.add(item);
                resultMap.put((String) item.get(criteria), groupedList);
            }
        }
        return resultMap;
    }
    
    
    public static Map < String, Set < Sobject >> generateMapStringSetOfObjects(List < Sobject > listOfData, String criteria) {
        Map <String, Set < Sobject >> resultMap = new Map < String, Set < Sobject >> ();
        
        for (Sobject item: listOfData) {
            
            if (resultMap.containsKey((String) item.get(criteria))) {
                resultMap.get((String) item.get(criteria)).add(item);
            }else {
                Set < Sobject > groupedList = new Set < Sobject > ();
                groupedList.add(item);
                resultMap.put((String) item.get(criteria), groupedList);
            }
        }
        return resultMap;
    }
    
    
     public static Id checkIfRecordIsUpdated(Sobject currentRecord , Sobject oldRecord, String fieldToCheck ){
        Boolean isUpdatedValues = false; 
        
        if(oldRecord.get(fieldToCheck.deleteWhitespace())   != currentRecord.get(fieldToCheck.deleteWhitespace()) ){
            System.debug( fieldToCheck.deleteWhitespace() +' '+'oldRecord---'+ oldRecord.get(fieldToCheck.deleteWhitespace())    +'   currentRecord---'+    currentRecord.get(fieldToCheck.deleteWhitespace())  );
            isUpdatedValues = true;
        }
        
        return isUpdatedValues ?  (String) currentRecord.get('Id') : null;
    }
    
    public static Id checkIfRecordIsUpdated(Sobject currentRecord , Sobject oldRecord, List<String> fieldsToCheckList ){
        Boolean isUpdatedValues = false; 
        
        for(String fieldToCheck : fieldsToCheckList){
            
            if(oldRecord.get(fieldToCheck.deleteWhitespace())   != currentRecord.get(fieldToCheck.deleteWhitespace()) ){
                System.debug( fieldToCheck.deleteWhitespace() +' '+'oldRecord---'+ oldRecord.get(fieldToCheck.deleteWhitespace())    +'   currentRecord---'+    currentRecord.get(fieldToCheck.deleteWhitespace())  );
                isUpdatedValues = true;
                continue;
            }
        }
        
        return isUpdatedValues ?  (String) currentRecord.get('Id') : null;
    }
    
    public static String parseResponseError(HttpResponse response){
        String errorMessage = 'HTTP Status: ' + response.getStatusCode()+' '+response.getStatus();
        try {
            if (isNotNull(response.getBody()) != null) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<String> values = new List<String>();
                for (String key : responseMap.keySet()) {
                    Object value = responseMap.get(key);
                    if (value != null) {
                        values.add(String.valueOf(value));
                    }
                }
                String concatenatedValues = String.join(values, ' ');
                if (!values.isEmpty()) {
                    errorMessage += ' - Details: ' + concatenatedValues;
                }
            }
        
        } catch (Exception ex) {
                System.debug('parseResponseError'+ex.getMessage()+' - '+ex.getLineNumber()+' - '+ex.getStackTraceString());
        } finally {
            return errorMessage ; 
        }
        return errorMessage ; 
    }
    class DataUtilsException extends Exception { }

    public static Datetime getDateTime(Object strDate) {
        if (strDate ==null) return null;
        DateTime returnDate ;
         try {
        // Replace 'T' with space and remove 'Z' for Salesforce compatibility
        String dateStr = getString(strDate);
        String formattedDate = dateStr.replace('T', ' ').replace('Z', '');
            return Datetime.valueOfGMT(formattedDate);
        } catch (Exception e) {
            returnDate = null; // Handle invalid formats gracefully
        }
       /*try {
        returnDate = DateTime.parse((String)strDate);
       }catch (Exception ex) {
        System.debug('Can not parse Date '+strDate);
        returnDate = null;
       }*/
       return returnDate ;
    }
    
    public static Date getDate(Object objVal) {
        if (objVal==null)return null;
        String strDate = DataUtils.getStringValue(objVal);
        Date returnDate = null;
        try {
            returnDate = Date.valueOf(strDate);
        }catch (Exception  ex) {
            List<String> dateParts = strDate.split('/');
                if (dateParts.size() == 3) {
                    Integer day = Integer.valueOf(dateParts[0]);
                    Integer month = Integer.valueOf(dateParts[1]);
                    Integer year = Integer.valueOf(dateParts[2]);
                    return Date.newInstance(year, month, day);
                }
            System.debug('Can not parse Date: ' + strDate + '. Error: ' + ex.getMessage());
            return null ; 
        }
        return returnDate ;
     }

    public static Date convertStringToDate(String dateStr) {
        try {
            List<String> dateParts = dateStr.split('/');
            Integer day = Integer.valueOf(dateParts[0]);
            Integer month = Integer.valueOf(dateParts[1]);
            Integer year = Integer.valueOf(dateParts[2]);
            
            return Date.newInstance(year, month, day);
        } catch(Exception e) {
            System.debug('Error converting date: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Parses a date string based on the specified format.
     * @param strDate The date string to parse.
     * @param format The format of the date string (e.g., "DD/MM/YYYY", "DD-MM-YYYY").
     * @return The parsed Date object, or null if the input is invalid.
     */
    public static Date getDate(Object strDate, String format) {
        if (strDate == null || String.isBlank(format)) {
            return null;
        }

        String dateStr = String.valueOf(strDate);
        try {
            // Split the format into parts (e.g., "DD", "MM", "YYYY")
            List<String> formatParts = format.split('[^a-zA-Z]');
            // Split the date string into parts based on the separator (e.g., "/", "-")
            List<String> dateParts = dateStr.split('[^0-9]');

            if (formatParts.size() != dateParts.size()) {
                throw new IllegalArgumentException('Date string does not match the specified format.');
            }

            // Map format parts to their corresponding date parts
            Map<String, Integer> dateMap = new Map<String, Integer>();
            for (Integer i = 0; i < formatParts.size(); i++) {
                dateMap.put(formatParts[i].toUpperCase(), Integer.valueOf(dateParts[i]));
            }

            // Extract day, month, and year from the map
            Integer day = dateMap.get('DD');
            Integer month = dateMap.get('MM');
            Integer year = dateMap.get('YYYY');

            // Validate the extracted values
            if (day == null || month == null || year == null) {
                throw new IllegalArgumentException('Invalid date format or missing components.');
            }

            // Return the parsed Date
            return Date.newInstance(year, month, day);
        } catch (Exception e) {
            System.debug('Error parsing date: ' + e.getMessage());
            return null;
        }
    }

    public static Map<String, String> parseJsonToFlattenedMap(Object jsonObject) {
        if  (jsonObject == null) return null;
        if (jsonObject instanceof String) {
            return parseJsonToFlattenedMap((String) jsonObject);
        } else if (jsonObject instanceof Map<String, Object>) {
            return parseJsonToFlattenedMap((Map<String, Object>) jsonObject);
        } else {
            return new Map<String, String>();
        }

    }
    public static Map<String, String> parseJsonToFlattenedMap(String jsonString) {
        Map<String, String> resultMap = new Map<String, String>();
        if (String.isBlank(jsonString)) {
            return resultMap; 
        }
        Map<String, Object> parsedMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        return parseJsonToFlattenedMap(parsedMap);
    }

     public static Map<String, String> parseJsonToFlattenedMap( Map<String, Object> parsedMap) {
        Map<String, String> resultMap = new Map<String, String>();
        if (parsedMap.isEmpty()) {
            return resultMap; 
        }

        try {
            // Recursively flatten the JSON structure
            flattenJsonMap(parsedMap, '', resultMap);
        } catch (Exception e) {
            System.debug('Error parsing JSON: ' + e.getMessage());
        }
        return resultMap;
     }
    // Helper method to recursively flatten nested JSON objects
    private static void flattenJsonMap(Map<String, Object> inputMap, String parentKey, Map<String, String> resultMap) {
        for (String key : inputMap.keySet()) {
            Object value = inputMap.get(key);
            String currentKey = String.isNotBlank(parentKey) ? parentKey + '.' + key : key;

            if (value instanceof Map<String, Object>) {
                // Recursively process nested maps
                flattenJsonMap((Map<String, Object>) value, currentKey, resultMap);
            } else if (value instanceof List<Object>) {
                // Handle arrays (optional: you can skip or format them)
                resultMap.put(currentKey, String.valueOf(value));
            } else if (value != null) {
                // Add primitives (String, Boolean, Number) to the map
                resultMap.put(currentKey, String.valueOf(value));
            }
        }
    }
    public static void simulatePause(Integer milliseconds) {
        Long startTime = DateTime.now().getTime();
        Integer i = 0;
        while (DateTime.now().getTime() < startTime + milliseconds) {
             i++;
        }
        System.debug('Pause terminée : ' + milliseconds + ' millisecondes.');
    }
}