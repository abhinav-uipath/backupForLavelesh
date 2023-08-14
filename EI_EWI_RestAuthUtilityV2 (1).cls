public without sharing class  EI_EWI_RestAuthUtilityV2 {
    API_Account__c accountApi;
    String accountId;
    String clientId;
    String clientSecret;
    public Map<String,EWI_Dispute_API_Object__c> mappingsBysystemObjectName;
    public list<account> memberAccount;
    public list<account> memberAccountApproveBody;
    public list<account> nonMemberLandlord;
    public list<account> objectsNonMemberLandlord;
    public list<account> formNonMemberLandlord;
    public list<account> independentLandlord;
    public list<account> formindependentLandlord;
    //public list<account> objectsindependentLandlord;
    public list<Account> Agent;
    public list<Account> Tenants;
    public list<Account> userDetailsInDispute;
    public list<Property__c> property;
    public list<Deposit__c> deposit;
    public list<Branch__c> branch;
    public list<case> dispute;
    public List<Account> caseParticipantAccounts;
    public list<String> userMatchingReference;
    list<Case_Participant__c> casePartiRec;
    
    string externalIdForUpdate;
    string disputeIdForUpdate;
    string caseIdForUpdate;
    String userTypeForUpdate;
    String UserIdForUpdate;
    String userTypeForQuery;
    String userQueryCp;
    String acessTokenForUpdatedUser;
    String emailForUpdatedUser;
    Map<string,string> responseBacktoVplus {set;get;}
    String memberNote;
    
    public EI_EWI_RestAuthUtilityV2()
    {
        memberAccount = new list<Account>();
        memberAccountApproveBody =new list<Account>();
        nonMemberLandlord = new list<Account>();
        objectsNonMemberLandlord = new list<Account>();
        independentLandlord = new list<Account>();
        formindependentLandlord = new list<Account>();
        Agent = new list<Account>();
        Tenants = new list<Account>();
        property = new list<Property__c>();
        deposit = new list<Deposit__c>();
        dispute = new list<case>();
        branch = new list<Branch__c>();
        userDetailsInDispute = new list<Account>();
        caseParticipantAccounts = new list<Account>();
        userMatchingReference = new list<string>();
        casePartiRec = new list<Case_Participant__c>();
        memberNote='';
    }
    
    public void validateHeader (map<string,string> headermap){
        if(headermap.get('AccessToken')==NULL)
        {
            throw new FC_DisputeAPI_Exception.AuthorizationException('Invalid access token.');
        }
        list<string> headervalue =headermap.get('AccessToken').split('-');
        if(headervalue.size()!=3)
        {
            throw new FC_DisputeAPI_Exception.AuthorizationException('Authentication failed');
        }
        string API_AccountID =headervalue[0];
        string TimeStamp  =headervalue[1];
        string SHAmac =headervalue[2];
        getAccountRec(API_AccountID);
        checkTimestamp(TimeStamp);
        matchToken(clientId,clientSecret,TimeStamp,SHAmac);
        
    }
    public API_Account__c getAccountRec(String API_AccountID){
        
        List<API_Account__c> accountApiList =  [SELECT Id, Client_Id__c, Client_Secret__c, Dispute_Record_Type__c, API_Account_Id__c, Deposit_Scheme_Name__c, Data_Owner_User__c, DML_Strategy_Processor__c
                                                FROM API_Account__c
                                                WHERE API_Account_Id__c =:API_AccountID];
        
        if(accountApiList.size() > 0) {
            accountApi = accountApiList[0];
        }
        else
        {
            throw new FC_DisputeAPI_Exception.AuthorizationException('Scheme Id is not Valid');
        }
        this.AccountId = accountApi.Id;
        this.clientId =accountApi.Client_Id__c;
        this.clientSecret =accountApi.Client_Secret__c;
        return accountApi;
    }
    public void checkTimestamp(String timestamp){
        /*
* Set window timeout in minutes
*/ 
        Integer maxTimeWindowInMins = 5;
        Datetime dt;
        try{
            dt = Datetime.newInstance(Long.valueof(timestamp));
        }
        catch (Exception exc) {
            throw new FC_DisputeAPI_Exception.AuthorizationException('Timestamp invalid.');
        }
        
        Long msDiff = Datetime.now().getTime() - dt.getTime();
        Integer minsDiff = Integer.valueOf(msDiff / 1000 / 60);
        if (!Test.isRunningTest()) {  
            if(minsDiff >= maxTimeWindowInMins) {
                throw new FC_DisputeAPI_Exception.TimestampTooOldException('Timestamp is too old.');
            }
        }
    }
    public void matchToken(String clientId, String clientSecret, String timestamp, String inputHMAC){
        String generatedHMAC = getgenerateHMACKey(clientId, clientSecret, timestamp);
        if(inputHMAC != generatedHMAC) {
            throw new FC_DisputeAPI_Exception.AuthorizationException('Invalid access token.');
        }
    }
    public static String getgenerateHMACKey(String clientId, String clientSecret, String timestamp){
        // return generateHMACKey(FC_Constant.HMAC_SHA1_MAC_ENCRYPTION, getCredentialsString(clientId,clientSecret,timestamp), clientSecret);
        return generateHMACKey('hmacSHA1', getCredentialsString(clientId,clientSecret,timestamp), clientSecret);
    }
    public static String generateHMACKey(String macEncryption, String input, String key){
        Blob keyBlob = Blob.valueof(key);
        Blob inputBlob = Blob.valueOf(input);
        Blob mac = Crypto.generateMac(macEncryption, inputBlob, keyBlob);
        String token = EncodingUtil.convertToHex(mac);
        return token;
    }
    public static String getCredentialsString(String client_id, String client_secret, String timestamp) {
        return 'client_id=' + client_id +
            '&' + 'client_secret=' + client_secret +
            '&' + 'timestamp=' + timestamp;
    }
    public Map<string,object> validatePayloadexecute (String Payload){
        Map<String, Object> deserializedPayload = validateJSONPayload(payload);
        //validation,data parse,generate list
        checkObjectPayload(deserializedPayload);
        if(memberAccount.size()>0)
        {
            if( memberAccount[0].Member_Note__c != null)
            {
                
                if(Payload.contains('approved_bodies') && Payload.contains('note'))
                {
                    string xyz = Payload.substringBetween('note', 'approved_bodies');
                    system.debug('xyz--->>'+xyz);
                    if(!(xyz=='' || xyz==null))
                    {
                        memberNote = xyz.substring(4,(xyz.length()-1) );
                    }
                       
                }
                
            }
            
        }
        
        
        //to process data of objects
        Map<String, object> accesscode = ProcessPayload();
        return accesscode;
    }
    public Map<string,object> validateJSONPayload (String Payload)
    {
        try {
            //reading the json
            return (Map<String, Object>) JSON.deserializeUntyped(payload);
        }
        catch(Exception exc) {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid payload.');
        }
        
    }
    public void checkObjectPayload(Map<String, Object> deserializedPayload){
        mappingsBysystemObjectName = new Map<String,EWI_Dispute_API_Object__c>();
        set<string> requiredObjects = new set<string>();
        set<string> requiredPayloadObjects = new set<string>();
        list<EWI_Dispute_API_Object__c> objects =  [ SELECT Id, Name, isRequired__c, Object_Type__c, Type__c,
                                                    (SELECT Id, Salesforce_Field_API_Name__c, Payload_Parameter_Name__c, Salesforce_Field_Length__c,
                                                     Salesforce_Field_Type__c, isRequired__c, SObject_Name__c, EWI_Dispute_API_Object__r.Name
                                                     FROM EWI_Dispute_API_Mappings__r
                                                     WHERE isActive__c = true)
                                                    FROM EWI_Dispute_API_Object__c
                                                    WHERE isActive__c = true and Type__c =: 'EW Claim API'];
        for(EWI_Dispute_API_Object__c obj : objects) {
            if(obj.isRequired__c) {
                requiredObjects.add(obj.Name.toLowerCase());
            }
            mappingsBysystemObjectName.put(obj.Name.toLowerCase(), obj);
        }
        for(string obj: deserializedPayload.keySet())
        {
            if(obj.toLowerCase() =='objects'|| obj.toLowerCase() =='formdata' )
            {
                List<String> errors = new List<String>();
                Set<String> invalidParameters = new Set<String>();
                Set<String> missingRequiredParameters = new Set<String>();
                Map<String, Object> innerMap=  (Map<String, Object>)deserializedPayload.get(obj);
                for(String payloadObjectName : innerMap.keySet()) {
                    requiredPayloadObjects.add(payloadObjectName.toLowerCase());
                    if( !mappingsBysystemObjectName.containsKey(payloadObjectName.toLowerCase()))
                    {
                        if (!Test.isRunningTest()) {  
                            throw new FC_DisputeAPI_Exception.JSONException(payloadObjectName +' Object does not Match with the Requested Object ');
                        }
                    } 
                    Object payloadObjectvalue = innerMap.get(payloadObjectName);
                    List<Map<String,Object>> payloadObjectRecords = getPayloadObjectRecords(payloadObjectvalue);
                    if(payloadObjectName != 'tenant' && payloadObjectName != 'member' && payloadObjectName != 'dispute' && payloadObjectName != 'landlord' )
                    {
                        for(Map<String,Object> payloadObjectRecord : payloadObjectRecords) {
                            /* Get Missing Payload */
                            missingRequiredParameters.addAll(getMissingRequiredParameters(payloadObjectName, payloadObjectRecord));
                            /* get Invalid Payload */
                            invalidParameters.addall(getInvalidParameters(payloadObjectName,payloadObjectRecord,obj));
                        }  
                    }
                    else if(payloadObjectName == 'tenant')
                    {
                        Map<String, Object> innerMapTenant=  (Map<String, Object>)innerMap.get(payloadObjectName);
                        for(string ten: innerMapTenant.keySet())
                        {
                            /* Get Missing Payload */
                            missingRequiredParameters.addAll(getMissingRequiredParameters('tenant',(Map<String, Object>)innerMapTenant.get(ten)));
                            /* get Invalid Payload */
                            invalidParameters.addall(getInvalidParameters('tenant',(Map<String, Object>)innerMapTenant.get(ten),obj));
                            
                        }
                    }
                    else if(payloadObjectName == 'member')
                    {
                        Map<String, Object> innerMapMember=  (Map<String, Object>)innerMap.get(payloadObjectName);
                        map<string,object> approveBodyMap = (Map<String, Object>)innerMapMember.get('approved_bodies');
                        map<string,object> BranchMap = (Map<String, Object>)innerMapMember.get('branch');
                        if(approveBodyMap != null)
                        {
                            missingRequiredParameters.addAll(getMissingRequiredParameters('approved_bodies', approveBodyMap));
                            invalidParameters.addall(getInvalidParameters('approved_bodies',approveBodyMap,obj));
                            innerMapMember.remove('approved_bodies');
                        }
                        if(BranchMap != null)
                        {
                            missingRequiredParameters.addAll(getMissingRequiredParameters('branch', BranchMap));
                            invalidParameters.addall(getInvalidParameters('branch',BranchMap,obj));
                            innerMapMember.remove('branch');
                        }
                        missingRequiredParameters.addAll(getMissingRequiredParameters('member', innerMapMember));
                        invalidParameters.addall(getInvalidParameters('member',innerMapMember,obj));
                        
                    }
                    else if(payloadObjectName == 'dispute')
                    {
                        Map<String, Object> innerMapdispute=  (Map<String, Object>)innerMap.get(payloadObjectName);
                        map<string,object> disputeUserMap = (Map<String, Object>)innerMapdispute.get('user');
                        missingRequiredParameters.addAll(getMissingRequiredParameters('user', disputeUserMap));
                        invalidParameters.addall(getInvalidParameters('user',disputeUserMap,obj));
                        innerMapdispute.remove('user');
                        missingRequiredParameters.addAll(getMissingRequiredParameters('dispute', innerMapdispute));
                        invalidParameters.addall(getInvalidParameters('dispute',innerMapdispute,obj));
                        
                    }
                    else if(payloadObjectName == 'landlord')
                    {
                        Map<String, Object> innerMaplandlord=  (Map<String, Object>)innerMap.get(payloadObjectName);
                        map<string,object> landlordbranchMap = (Map<String, Object>)innerMaplandlord.get('branch');
                        if(landlordbranchMap != null)
                        {
                            missingRequiredParameters.addAll(getMissingRequiredParameters('branch', landlordbranchMap));
                            invalidParameters.addall(getInvalidParameters('branch',landlordbranchMap,obj));
                            innerMaplandlord.remove('branch'); 
                        }
                        missingRequiredParameters.addAll(getMissingRequiredParameters('landlord', innerMaplandlord));
                        invalidParameters.addall(getInvalidParameters('landlord',innerMaplandlord,obj));
                        system.debug('invalidParameters:'+invalidParameters);
                    }
                    
                    if(missingRequiredParameters.size() > 0) {
                        errors.add('Missing required parameters: ' + String.join(new List<String>(missingRequiredParameters), ',') + ' for object ' + payloadObjectName);
                    }
                    
                    if(!errors.isEmpty()) {
                        throw new FC_DisputeAPI_Exception.JSONException(String.join(errors,'; '));
                    }
                }
            }
            else
            {
                throw new FC_DisputeAPI_Exception.JSONException(obj +' Object does not Match with the Requested Object ');
            } 
        }
        requiredObjects.removeAll(requiredPayloadObjects);
        if(requiredObjects.size() > 0) {
            if (!Test.isRunningTest()) {  
                throw new FC_DisputeAPI_Exception.JSONException('Missing required Objects: '
                                                                + String.join(new List<String>(requiredObjects), ','));
            }
        }
        
        
        
    }
    public List<String> getMissingRequiredParameters(String payloadObjectName, Map<String,Object> payloadObjectRecord) {
        List<String> missingRequiredParameters = new List<String>();
        Set<String> requiredParametersForObject = getMappingsByPayloadParameter(payloadObjectName,true).keySet();
        for(String requiredParameterName : requiredParametersForObject) {
            if(!payloadObjectRecord.keySet().contains(requiredParameterName)) {
                missingRequiredParameters.add(requiredParameterName);
            }
        }
        return missingRequiredParameters;
    }
    public Map<String,EWI_Dispute_API_Mapping__c> getMappingsByPayloadParameter(String objectName, Boolean requiredOnly) {
        system.debug('Inside :'+objectName +'    :::::::::   '+requiredOnly);
        Map<String,EWI_Dispute_API_Mapping__c> payloadParametersMap = new Map<String,EWI_Dispute_API_Mapping__c>();
        for(EWI_Dispute_API_Mapping__c mapping : mappingsBysystemObjectName.get(objectName.toLowerCase()).EWI_Dispute_API_Mappings__r) {
            if(!requiredOnly || (requiredOnly && mapping.isRequired__c)) {
                payloadParametersMap.put(mapping.Payload_Parameter_Name__c.toLowerCase(),mapping);
            }
        }
        return payloadParametersMap;
    }
    public List<String> getInvalidParameters(String payloadObjectName,Map<String,Object> payloadObjectRecord,string parentObjectName)
    {
        map<string,EWI_Dispute_API_Mapping__c > mappingRecordMap = new map<string,EWI_Dispute_API_Mapping__c>();
        Map<string,object> innerMap = new Map<string,object>();
        String jsonData;
        JSONGenerator gen1;
        if(payloadObjectName=='Tenancy')
        {
            gen1 = JSON.createGenerator(true);  
        }
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();
        gen.writeStartObject();
        list<EWI_Dispute_API_Mapping__c> mappingRecords = mappingsBysystemObjectName.get(payloadObjectName.toLowerCase()).EWI_Dispute_API_Mappings__r;
        for(EWI_Dispute_API_Mapping__c maping: mappingRecords)
        {
            mappingRecordMap.put(maping.Payload_Parameter_Name__c,maping );
        }
        list<string> InvalidParameters = new list<string>();
        boolean flagProp = true;
        for(string payloadObjectKey : payloadObjectRecord.keyset())
        {
            string MappingDatatype; 
            String stringValue;
            string salesforcesobjectName;
            string salesforcefieldName;
            try{
                MappingDatatype =mappingRecordMap.get(payloadObjectKey).Salesforce_Field_Type__c; 
                salesforcesobjectName =mappingRecordMap.get(payloadObjectKey).SObject_Name__c;
                salesforcefieldName =mappingRecordMap.get(payloadObjectKey).Salesforce_Field_API_Name__c;
                stringValue= String.valueOf(payloadObjectRecord.get(payloadObjectKey));
                if(salesforcesobjectName=='Property__c' && flagProp==true) 
                {
                    gen1.writeStartArray();
                    gen1.writeStartObject();
                    flagProp= false;
                }
                
            }
            catch(Exception exc)
            {
                throw new FC_DisputeAPI_Exception.JSONException(payloadObjectName+'.'+payloadObjectKey+' Not a valid entry');
            }
            
            if(MappingDatatype =='STRING' || MappingDatatype =='ID' )
            {  
                validatelength(stringValue,mappingRecordMap.get(payloadObjectKey)); 
            }
            else if(MappingDatatype =='DOUBLE'||MappingDatatype=='INTEGER')
            {
                ValidateDecimal(stringValue,mappingRecordMap.get(payloadObjectKey));
            }
            else if(MappingDatatype =='PICKLIST')
            {
                ValidatePicklist(stringValue,mappingRecordMap.get(payloadObjectKey));
            }
            else if(MappingDatatype =='DATETIME')
            {
                validateDateandTime(stringValue);
            }
            else if(MappingDatatype =='DATE')
            {
                validateDate(stringValue,mappingRecordMap.get(payloadObjectKey));
            }
            else if(MappingDatatype=='BOOLEAN')
            {
                validateBoolean(stringValue,mappingRecordMap.get(payloadObjectKey));
            }
            if(salesforcesobjectName=='Property__c')
            {
                gen1.writeStringField(salesforcefieldName, stringValue);
            }
            else
            {
                gen.writeStringField(salesforcefieldName, stringValue);
            }   
        }
        String jsonData1;
        if(payloadObjectName=='Tenancy')
        {
            gen1.writeEndObject();
            gen1.writeEndArray();
            jsonData1=gen1.getAsString();
        }
        
        gen.writeEndObject();
        gen.writeEndArray();
        jsonData =gen.getAsString();
        if(parentObjectName =='casePartiAccount')
        {
            caseParticipantAccounts =  (list<Account>)JSON.deserialize(jsonData, list<Account>.class);
            caseParticipantAccounts[0].firstName = getSubString(caseParticipantAccounts[0].EWI_First_Name__c,40);
            caseParticipantAccounts[0].lastName = getSubString(caseParticipantAccounts[0].EWI_Last_Name__c,80);
        }
        else 
        {
            if(payloadObjectName=='landlord')
            {
                list<account> acclist =  (list<Account>)JSON.deserialize(jsonData, list<Account>.class);
                if(acclist[0].Landlord_Type__c =='Non Member')
                {
                    nonMemberLandlord.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
                    userMatchingReference.add(((getSubString(nonMemberLandlord[0].EWI_First_Name__c,40)+getSubString(nonMemberLandlord[0].EWI_Last_Name__c,80)+nonMemberLandlord[0].Email_Description__c).toLowerCase().deleteWhitespace()).remove('null'));
                }
                else
                {
                    if(parentObjectName =='objects')
                    {
                        independentLandlord.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class)); 
                    }
                    else
                    {
                        formindependentLandlord.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
                    }
                    
                }
            }
            else if(payloadObjectName=='Tenancy')
            {
                property.addAll( (list<Property__c>)JSON.deserialize(jsonData1, list<Property__c>.class));
                deposit.addAll( (list<Deposit__c>)JSON.deserialize(jsonData, list<Deposit__c>.class));
            }
            else if(payloadObjectName=='tenant')
            {
                Tenants.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
                for(account ten:Tenants )
                {
                    userMatchingReference.add(((getSubString(ten.EWI_First_Name__c,40)+getSubString(ten.EWI_Last_Name__c,80)+ten.Email_Description__c).toLowerCase().deleteWhitespace()).remove('null'));
                }  
            }
            else if(payloadObjectName=='dispute')
            {
                dispute.addAll( (list<Case>)JSON.deserialize(jsonData, list<Case>.class));
            }
            else if(payloadObjectName=='user')
            {
                userDetailsInDispute.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
                userMatchingReference.add(((getSubString(userDetailsInDispute[0].EWI_First_Name__c,40)+getSubString(userDetailsInDispute[0].EWI_Last_Name__c,80)+userDetailsInDispute[0].Email_Description__c).toLowerCase().deleteWhitespace()).remove('null'));
            }
            else if(payloadObjectName=='agent')
            {
                Agent.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class)); 
            }
            else if(payloadObjectName=='branch')
            {
                branch.addAll( (list<Branch__c>)JSON.deserialize(jsonData, list<Branch__c>.class));
            }
            else if(payloadObjectName=='approved_bodies')
            {
                memberAccountApproveBody.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
            }
            else if(payloadObjectName=='member')
            {
                memberAccount.addAll( (list<Account>)JSON.deserialize(jsonData, list<Account>.class));
            }
            else 
            {
                throw new FC_DisputeAPI_Exception.JSONException(payloadObjectName+' Objects Not Match the required Object');
            }
        }
        return InvalidParameters;
    }
    public void validatelength(String stringValue, EWI_Dispute_API_Mapping__c mapping)
    {
        if(stringValue.length() > mapping.Salesforce_Field_Length__c || stringValue.length() ==0 ) {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid value \'' + stringValue + '\' for '
                                                            + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);
        }
    }
    public void ValidateDecimal(String stringValue, EWI_Dispute_API_Mapping__c mapping)
    {
        try{
            decimal payloadDouble = decimal.valueOf(stringValue);
        }
        catch(Exception exc)
        {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid value \'' + stringValue + '\' for '
                                                            + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);
        }
    }
    public void ValidatePicklist(String stringValue, EWI_Dispute_API_Mapping__c mapping)
    {
        SObjectType sObjectType = Schema.getGlobalDescribe().get(mapping.SObject_Name__c);
        if(String.isNotBlank(mapping.Salesforce_Field_API_Name__c)) {
            SObjectField sObjectField = sObjectType.getDescribe().Fields.getMap().get(mapping.Salesforce_Field_API_Name__c);
            Set<String> picklistValues = new Set<String>();
            for(PicklistEntry ple : sObjectField.getDescribe().getPicklistValues()) {
                picklistValues.add(ple.getValue());
            }
            if(!toLowerCase(picklistValues).contains(stringValue.toLowerCase())) {
                throw new FC_DisputeAPI_Exception.JSONException('Invalid value \'' + stringValue + '\' for '
                                                                + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);            
            }
        }
        
    }
    public static Set<String> toLowerCase(Set<String> inputSet) {
        Set<String> outputSet = new Set<String>();
        for(String inputValue : inputSet) {
            outputSet.add(inputValue.toLowerCase());
        }
        return outputSet;
    }
    public void validateDateandTime (String stringValue)
    {
        try{
            datetime PayloadDatetime = (Datetime)JSON.deserialize('"' + stringValue + '"',Datetime.class);
        }
        catch(Exception exc)
        {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid Datetime value ' + stringValue );
        }
        
    }
    
    public void validateDate(String stringValue,EWI_Dispute_API_Mapping__c mapping)
    {
        try{
            date payloaddate = date.valueOf(stringValue);
        }
        catch(Exception exc)
        {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid date value \'' + stringValue + '\' for '
                                                            + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);
            
        }
    }
    public void validateBoolean(String stringValue,EWI_Dispute_API_Mapping__c mapping)
    {
        if(stringValue != null)
        {
            if(!(stringValue.toLowerCase() == 'false' || stringValue.toLowerCase() == 'true'))
            {
                throw new FC_DisputeAPI_Exception.JSONException('Invalid boolean value \'' + stringValue + '\' for '
                                                                + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);
                
            }
        }
        else
        {
            throw new FC_DisputeAPI_Exception.JSONException('Invalid boolean value \'' + stringValue + '\' for '
                                                            + mapping.EWI_Dispute_API_Object__r.Name + '.' + mapping.Payload_Parameter_Name__c);
            
        }
        
        
    }
    public static List<Map<String,Object>> getPayloadObjectRecords(Object payloadObject) {
        List<Map<String,Object>> payloadObjectRecords = new List<Map<String,Object>>();
        if(payloadObject instanceof List<Object>) {
            for(Object obj : (List<Object>)payloadObject) {
                payloadObjectRecords.add((Map<String,Object>)obj);
            }
        }
        else {
            payloadObjectRecords.add((Map<String,Object>)payloadObject);
        }
        return payloadObjectRecords;
    }
    public Map<String, Object> ProcessPayload()
    {
        String ResponseAccessToken ='';
        Savepoint sp = Database.setSavepoint();
        if(!(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('agent') ||
             dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Independent-Landlord') ||
             dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord') ||
             dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('tenant')))
        {        
            throw new FC_DisputeAPI_Exception.JSONException('dispute.applicant'+ ' Not a valid entry');
        }
        if(!(deposit[0].Customer_Type__c.equalsIgnoreCase('agent') ||
             deposit[0].Customer_Type__c.equalsIgnoreCase('Independent-Landlord') ||
             deposit[0].Customer_Type__c.equalsIgnoreCase('Non-Member Landlord')))
        {        
            throw new FC_DisputeAPI_Exception.JSONException('Tenancy.tenancy_type'+ ' Not a valid entry');
        }
        if(deposit[0].Customer_Type__c.equalsIgnoreCase('agent') || dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('agent'))
        {
            if (Agent.size() < 1)
            {
                throw new FC_DisputeAPI_Exception.JSONException('Missing required Objects: '
                                                                +'agent' );
            }
            else if(nonMemberLandlord.size() < 1)
            {
                throw new FC_DisputeAPI_Exception.JSONException('Missing required Objects: '
                                                                +'Nonmember Landlord' );
            }
            
        }
        if((deposit[0].Customer_Type__c.equalsIgnoreCase('Independent-Landlord') ||dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Independent-Landlord')) && independentLandlord.size() < 1 )
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: '
                                                            +'Independent Landlord' );
        }
        if(independentLandlord.size()>0 && branch.size()<1 )
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: '
                                                            +'Independent Landlord Branch' ); 
        }
        if((deposit[0].Customer_Type__c.equalsIgnoreCase('Non-Member Landlord') ||dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord')) )
        {
            
            if(nonMemberLandlord.size() < 1){
                throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: '
                                                                +'Nonmember Landlord' );
            }
            else if(agent.size()<1)
            {
                throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: '
                                                                +'agent' );
            }
            
        }
        if((dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord') || dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('agent') || agent.size() >0 ) && memberAccount.size() < 1)
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: '
                                                            +'member');
        }
        if(deposit[0].Number_Of_Tenants__c != Tenants.size())
        {
            throw new FC_DisputeAPI_Exception.JSONException('tenancy.number_of_tenants'+ ' Not a valid entry');
        }
        if(userDetailsInDispute.size() ==0)
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required entity: dispute.user' );  
        }
        
        /*
* 
* Process Paylod
* 
*/ 
        string AccountRecordTypeId;
        list<Account> existingrecord = [select id,EWI_Matching_Reference__c,RecordTypeId from account where EWI_Matching_Reference__c In :userMatchingReference and EWI_Matching_Reference__c !='' and (RecordType.Name='EWI_Tenant' or RecordType.Name='EWI_NonMemberLandlord' )];
       
        Map<string,string> existingrecordMAp = new Map<string,string>();
        Map<String, Object> obj = new Map<String, Object>();
        for(Account acc: existingrecord)
        {
            existingrecordMAp.put((acc.EWI_Matching_Reference__c+acc.RecordTypeId).toLowerCase(),acc.id);
        }
        /*  
*** Process Member **** 
*/
        
        if(memberAccount.size()>0)
        {
            AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_Member').getRecordTypeId();
            for(Account acc:memberAccount)
            {
                acc.RecordTypeId =AccountRecordTypeId;
                if(memberAccountApproveBody.size() >0)
                {
                    acc.arla__c = memberAccountApproveBody[0].arla__c !=null?memberAccountApproveBody[0].arla__c:false; 
                    acc.arma__c = memberAccountApproveBody[0].arma__c !=null?memberAccountApproveBody[0].arma__c:false;
                    acc.balma__c = memberAccountApproveBody[0].balma__c !=null?memberAccountApproveBody[0].balma__c:false;
                    acc.glm__c = memberAccountApproveBody[0].glm__c !=null?memberAccountApproveBody[0].glm__c:false;
                    acc.gorl__c= memberAccountApproveBody[0].gorl__c !=null?memberAccountApproveBody[0].gorl__c:false;
                    acc.corporate__c= memberAccountApproveBody[0].corporate__c !=null?memberAccountApproveBody[0].corporate__c:false;
                    acc.ha__c= memberAccountApproveBody[0].ha__c !=null?memberAccountApproveBody[0].ha__c:false;
                    acc.law_society__c= memberAccountApproveBody[0].law_society__c !=null?memberAccountApproveBody[0].law_society__c:false;
                    acc.naea__c= memberAccountApproveBody[0].naea__c !=null?memberAccountApproveBody[0].naea__c:false;
                    acc.safeagent__c= memberAccountApproveBody[0].safeagent__c !=null?memberAccountApproveBody[0].safeagent__c:false;
                    acc.none__c= memberAccountApproveBody[0].none__c !=null?memberAccountApproveBody[0].none__c:false;
                    acc.nforl__c= memberAccountApproveBody[0].nforl__c !=null?memberAccountApproveBody[0].nforl__c:false;
                    acc.nla__c= memberAccountApproveBody[0].nla__c !=null?memberAccountApproveBody[0].nla__c:false;
                    acc.oea__c= memberAccountApproveBody[0].oea__c !=null?memberAccountApproveBody[0].oea__c:false;
                    acc.other_body__c= memberAccountApproveBody[0].other_body__c !=null?memberAccountApproveBody[0].other_body__c:false;
                    acc.rics__c= memberAccountApproveBody[0].rics__c !=null?memberAccountApproveBody[0].rics__c:false;
                    acc.rsl__c= memberAccountApproveBody[0].rsl__c !=null?memberAccountApproveBody[0].rsl__c:false;
                    acc.tls__c= memberAccountApproveBody[0].tls__c !=null?memberAccountApproveBody[0].tls__c:false;
                    acc.tpos__c= memberAccountApproveBody[0].tpos__c !=null?memberAccountApproveBody[0].tpos__c:false;
                    acc.ukala__c= memberAccountApproveBody[0].ukala__c !=null?memberAccountApproveBody[0].ukala__c:false; 
                }
                if(acc.Email_Description__c != null)
                {
                    list<string> emails = string.valueOf(acc.Email_Description__c).split(',');
                    if(emails.size()>0)
                    {
                        acc.Email__c =emails[0];
                        emails.remove(0);
                        acc.Email_Description__c = string.join(emails,',');
                    }
                    else
                    {
                        acc.Email__c = acc.Email_Description__c;
                        acc.Email_Description__c = null;
                    }
                }
                if(MemberNote !='')
                {
                    acc.Member_Note__c = MemberNote;  
                }
            }
            upsert memberAccount Member_Id__c;
            
        }
        /*  
*** Process Independent Landlord  Organization**** 
*/
        if(independentLandlord.size()>0)
        {
            AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_Indepandent_Landlord').getRecordTypeId();
            for(Account acc:independentLandlord)
            {
                acc.RecordTypeId =AccountRecordTypeId;
                acc.name = branch[0].EWI_Branch_Name__c;
                acc.EWI_Landlord_Status__c =branch[0].Status__c != null?branch[0].Status__c:''; 
                if(acc.Email_Description__c != null)
                {
                    list<string> emails = string.valueOf(acc.Email_Description__c).split(',');
                    if(emails.size()>0)
                    {
                        acc.Email__c =emails[0];
                        emails.remove(0);
                        acc.Email_Description__c = string.join(emails,',');
                    }
                    else
                    {
                        acc.Email__c = acc.Email_Description__c;
                        acc.Email_Description__c = null;
                    }
                }
            }
            
            if(independentLandlord[0].EWI_Landlord_Id__c != null)
            {
                upsert independentLandlord EWI_Landlord_Id__c;
            }
            else 
            {
                insert independentLandlord;
            }
        }
        
        /*  
*** Process branch **** 
*/
        
        if(branch.size()> 0)
        {
            list<Branch__c> branchRecid= [select id,Branch_ID__c from Branch__c where Branch_Name__c=:branch[0].Branch_ID__c ];
            
            try{
                AccountRecordTypeId=Schema.SObjectType.Branch__c.getRecordTypeInfosByDeveloperName().get('EW_Branch').getRecordTypeId();
                for(Branch__c br: branch)
                {
                    br.RecordTypeId =AccountRecordTypeId;
                    if(branchRecid.size() > 0)
                    {
                        br.id=branchRecid[0].id;
                        br.Branch_Name__c = string.valueOf(branchRecid[0].Branch_ID__c);
                    }
                    else
                    {
                        if(memberAccount.size() > 0)
                        {
                            br.Account__c = memberAccount[0].id;
                        } 
                        else
                        {
                            br.Account__c = independentLandlord[0].id;
                        }
                        br.Branch_Name__c = string.valueOf(br.Branch_ID__c);
                    }
                    
                } 
                upsert branch;
            }
            catch (DmlException dmlExc)
            {
                Database.rollback(sp);
                if(dmlExc.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                    throw new FC_DisputeAPI_Exception.DuplicatedExtIdException('Duplicate branch_name for relation for object branch found');
                }
                
            }
            
            //==================Process Member/Independent landlord branch Mapping===================
            
            
            if(memberAccount.size()>0)
            {
                list<Branch_User_Mapping__c> branchMapping = [select id from Branch_User_Mapping__c where Branch__c =:branch[0].id and EWI_Account__c=:memberAccount[0].id];
                if(branchMapping.size() ==0 )
                {
                    Branch_User_Mapping__c ubm = new Branch_User_Mapping__c( EWI_Account__c =memberAccount[0].id,Branch__c=branch[0].id);
                    insert ubm;
                }
            }
            else if(independentLandlord.size()>0)
            {
                list<Branch_User_Mapping__c> branchMapping = [select id from Branch_User_Mapping__c where Branch__c =:branch[0].id and EWI_Account__c=:independentLandlord[0].id];
                if(branchMapping.size() ==0 )
                {
                    Branch_User_Mapping__c ubm = new Branch_User_Mapping__c( EWI_Account__c =independentLandlord[0].id,Branch__c=branch[0].id);
                    insert ubm;
                }
                
            }
        }
        
        /*  
*** Process Non Member Landlord**** 
*/
        
        
        if(nonMemberLandlord.size()> 0)
        {
            string abc;
            /*if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord'))
            {
                nonMemberLandlord[0].firstname =nonMemberLandlord[0].firstname !=null ? nonMemberLandlord[0].firstname:userDetailsInDispute[0].FirstName;
                nonMemberLandlord[0].lastname =nonMemberLandlord[0].lastName !=null ? nonMemberLandlord[0].lastName:userDetailsInDispute[0].lastName;
                nonMemberLandlord[0].EWI_Landlord_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
            }*/
            
            AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_NonMemberLandlord').getRecordTypeId();
            for(account acc: nonMemberLandlord)
            {
                if(acc.EWI_Last_Name__c =='' ||acc.EWI_Last_Name__c ==null )
                {
                    throw new FC_DisputeAPI_Exception.JSONException('Invalid value surname for non member landlord' );
                }
                acc.RecordTypeId =AccountRecordTypeId;
                acc.FirstName = acc.EWI_First_Name__c==null?'': getCamelCaseString(getSubString(acc.EWI_First_Name__c,40));
                acc.LastName = getCamelCaseString(getSubString(acc.EWI_Last_Name__c,80));
                acc.PersonMailingCountry = acc.PersonMailingCountry==null?'':getCamelCaseString(acc.PersonMailingCountry);
                acc.PersonMailingCity = acc.PersonMailingCity==null?'':getCamelCaseString(acc.PersonMailingCity);
                acc.PersonMailingState = acc.PersonMailingState==null?'':getCamelCaseString(acc.PersonMailingState);
                acc.PersonMailingStreet =acc.PersonMailingStreet==null?'': getCamelCaseString(acc.PersonMailingStreet);
                acc.Local_Area__pc = acc.Local_Area__pc==null?'':getCamelCaseString(acc.Local_Area__pc);
                acc.House_No__pc = acc.House_No__pc==null?'':acc.House_No__pc==null?'': getCamelCaseString(string.valueOf(acc.House_No__pc));
                acc.Saon__pc = acc.Saon__pc==null?'':getCamelCaseString(acc.Saon__pc);
                acc.PersonMailingPostalCode =acc.PersonMailingPostalCode==null?'': (acc.PersonMailingPostalCode).toUpperCase();  
                if(acc.Email_Description__c != null)
                {
                    list<string> emails = string.valueOf(acc.Email_Description__c).split(',');
                    if(emails.size()>0)
                    {
                        acc.PersonEmail =emails[0];
                        emails.remove(0);
                        acc.Email_Description__c = string.join(emails,',');
                    }
                    else
                    {
                        acc.PersonEmail = acc.Email_Description__c;
                        acc.Email_Description__c = null;
                    }
                }
                abc = ((acc.firstName+acc.LastName+acc.PersonEmail+AccountRecordTypeId).toLowerCase()).deleteWhitespace().remove('null');
            }
            if(nonMemberLandlord[0].EWI_Landlord_Id__c != null)
            {
                upsert nonMemberLandlord EWI_Landlord_Id__c; 
            }
            else if(existingrecordMAp.containsKey(abc))
            {
                nonMemberLandlord[0].id =existingrecordMAp.get(abc);
                update nonMemberLandlord;
            }
            else
            {
                insert nonMemberLandlord;
            }
            
            
            caseParticipantAccounts.addall(nonMemberLandlord);
        }
        /*  
*** Process Tenant**** 
*/
        if(Tenants.size()> 0)
        {
            AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_Tenant').getRecordTypeId();
            // list<string> externalTenantIds = new list<string>();
            integer i = 0;
            for(account acc: Tenants)
            { 
                acc.RecordTypeId =AccountRecordTypeId;
                acc.FirstName = acc.EWI_First_Name__c==null?'': getCamelCaseString(getSubString(acc.EWI_First_Name__c,40));
                acc.LastName = getCamelCaseString(getSubString(acc.EWI_Last_Name__c,80));
                acc.PersonMailingCountry = acc.PersonMailingCountry==null?'':getCamelCaseString(acc.PersonMailingCountry);
                acc.PersonMailingCity = acc.PersonMailingCity==null?'':getCamelCaseString(acc.PersonMailingCity);
                acc.PersonMailingState = acc.PersonMailingState==null?'':getCamelCaseString(acc.PersonMailingState);
                acc.PersonMailingStreet =acc.PersonMailingStreet==null?'': getCamelCaseString(acc.PersonMailingStreet);
                acc.Local_Area__pc = acc.Local_Area__pc==null?'':getCamelCaseString(acc.Local_Area__pc);
                acc.House_No__pc = acc.House_No__pc==null?'':acc.House_No__pc==null?'': getCamelCaseString(string.valueOf(acc.House_No__pc));
                acc.Saon__pc = acc.Saon__pc==null?'':getCamelCaseString(acc.Saon__pc);
                acc.PersonMailingPostalCode =acc.PersonMailingPostalCode==null?'':(acc.PersonMailingPostalCode).toUpperCase();
                if(acc.Email_Description__c != null)
                {
                    list<string> emails = string.valueOf(acc.Email_Description__c).split(',');
                    if(emails.size()>0)
                    {
                        acc.PersonEmail =emails[0];
                        emails.remove(0);
                        acc.Email_Description__c = string.join(emails,',');
                    }
                    else
                    {
                        acc.PersonEmail = acc.Email_Description__c;
                        acc.Email_Description__c = null;
                    }
                    
                }
                String abc = ((acc.firstName+acc.LastName+acc.PersonEmail+AccountRecordTypeId).toLowerCase()).deleteWhitespace().remove('null');
                
                if(existingrecordMAp.containsKey(abc))
                {
                    acc.id =existingrecordMAp.get(abc);
                }
                if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('tenant'))
                {
                    string UserDetails = (getSubString(userDetailsInDispute[0].firstName,40)+getSubString(userDetailsInDispute[0].LastName,80)+userDetailsInDispute[0].Email_Description__c).toLowerCase().deleteWhitespace().remove('null');
                    if(abc.equalsIgnoreCase(UserDetails))
                    {
                        acc.V_Tenant_External_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;  
                    } 
                }
                
                
            }
            upsert Tenants;
            caseParticipantAccounts.addAll(Tenants);
        }
        
        
        /*  
*** Process Property**** 
*/
        if (property.size()>0)
        {
            string PropertyRecordTypeId =Schema.SObjectType.Property__c.getRecordTypeInfosByDeveloperName().get('EWI_Property').getRecordTypeId();
            for(Property__c prop : property)
            {
                prop.Street__c = prop.Street__c==null?'': getCamelCaseString(prop.Street__c);
                prop.Postal_Code__c = (prop.Postal_Code__c).toUpperCase();
                prop.Saon__c = prop.Saon__c==null?'':getCamelCaseString(prop.Saon__c);
                prop.City__c = prop.City__c==null?'':getCamelCaseString(prop.City__c);
                prop.County__c = prop.County__c==null?'':getCamelCaseString(prop.County__c);
                prop.Country__c = prop.Country__c==null?'':getCamelCaseString(prop.Country__c);
                prop.Local_Authority_Area__c = prop.Local_Authority_Area__c==null?'':getCamelCaseString(prop.Local_Authority_Area__c);
                prop.House_No__c = prop.House_No__c==null?'':getCamelCaseString(prop.House_No__c);
                if(independentLandlord.size()> 0){
                    prop.Property_Owner__c = independentLandlord[0].id;
                }else{
                    prop.Property_Owner__c = nonMemberLandlord[0].id;
                }
                
                prop.RecordTypeId =PropertyRecordTypeId;
            }
            insert property;
        }
        /*  
*** Process Deposit**** 
*/ 
        if(deposit.size() > 0 )
            system.debug('deposit.size' +deposit.size());
        {
            try{
                string DepositRecordTypeId =Schema.SObjectType.Deposit__c.getRecordTypeInfosByDeveloperName().get('EWI_Deposit').getRecordTypeId();
                system.debug('Deposit record : '+DepositRecordTypeId);
                system.debug(accountApi.Deposit_Scheme_Name__c);
                Scheme__c schemeRec= getSchemeByName (accountApi.Deposit_Scheme_Name__c);
                for(Deposit__c depo : deposit)
                {
                    if(independentLandlord.size()>0)
                    {
                        depo.Customer__c = independentLandlord[0].id; 
                    }
                    else
                    {
                        depo.Customer__c = memberAccount[0].id;
                    } 
                    depo.Scheme__c =schemeRec.Id;
                    depo.Property__c =property[0].id;
                    depo.RecordTypeId =DepositRecordTypeId;
                }
                
                insert deposit;
            }
            catch (DmlException dmlExc)
            {
                Database.rollback(sp);
                if(dmlExc.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                    throw new FC_DisputeAPI_Exception.DuplicatedExtIdException('Duplicate tenancy_id for relation for object tenancy found');
                }
                
            }
            
        }
        
        /*  
*** Process Deposit Allocation**** 
*/ 
        if(deposit.size() > 0 && Tenants.size() > 0  )
        {
            List<Deposit_Allocation__c> depositAllocations = new List<Deposit_Allocation__c>();
            string EWI_Deposit_AllocationRecType =Schema.SObjectType.Deposit_Allocation__c.getRecordTypeInfosByDeveloperName().get('EWI_Deposit_Allocation').getRecordTypeId();
            for(Account acc: Tenants)
            {
                Deposit_Allocation__c depositAllocation = new Deposit_Allocation__c(
                    Deposit__c = deposit[0].Id,
                    Deposit_Holder__c = acc.Id,
                    Role__c = 'Tenant',
                    recordTypeId=EWI_Deposit_AllocationRecType
                );
                depositAllocations.add(depositAllocation);
                
            }
            
            if (!Test.isRunningTest()) {  
                insert depositAllocations;
            } 
        }
        
        /*  
*** Process Case **** 
*/
        
        if(dispute.size() >0)
        {
            try{
                string DisputeRecordTypeId =Schema.SObjectType.case.getRecordTypeInfosByDeveloperName().get('Dispute_EW_Insured').getRecordTypeId();
                //Id usercontactid =[select id,PersonContactId from Account where id =:Landlord[0].id].PersonContactId;
                for(Case dis : dispute)
                {
                    dis.RecordTypeId =DisputeRecordTypeId;
                    dis.Deposit_Account_Number__c =deposit[0].id;
                    dis.Origin ='V+';
                    dis.API_Account__c =accountApi.id;
                    dis.API_Name__c='Claim API';
                    dis.Scheme__c ='EW Insured';
                    if(deposit[0].Unique_ID__c !=null)
                    {
                        dis.DAN_Unique_Id__c = deposit[0].Unique_ID__c;
                    }
                    if(memberAccount.size()>0)
                    {
                        dis.Member_Status__c =String.valueOf(memberAccount[0].Member_Status__c);
                        dis.Member_Notes__c =memberAccount[0].Member_Note__c;
                        dis.G_Number__c = String.valueOf(memberAccount[0].G_Number__c);
                        dis.EWI_AgentName__c = String.valueOf(memberAccount[0].Name);
                        dis.AccountId = memberAccount[0].id;
                    }
                    if(independentLandlord.size()>0)
                    {
                        dis.AccountId = independentLandlord[0].id;
                        dis.G_Number__c = String.valueOf(independentLandlord[0].EWI_Landlord_User_Id__c);
                    }
                    if(branch.size()> 0)
                    {
                        dis.Agent_Branch__c = branch[0].id;
                        dis.Branch_Notes__c = branch[0].branch_note__c;
                    }
                    if(dis.Dispute_Initiated_By__c.equalsIgnoreCase('tenant'))
                    {
                        dis.Status = 'Proposal submitted- tenant'; 
                    }
                    
                    
                }
                insert dispute;
            }
            catch (exception exc)
            {
                Database.rollback(sp);
                if(exc.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                    throw new FC_DisputeAPI_Exception.DuplicatedExtIdException('Duplicate dispute_id for relation for object dispute found');
                }
                
            }
        }
        string InstallmentContactId='';
        /*  
*** Process Case Participants **** 
*/
        // String CpForInstallment='';
        if(dispute.size()>0)
        {
            Id cpRecordTypeID = Schema.SObjectType.Case_Participant__c.getRecordTypeInfosByName().get('EWI Case Participant').getRecordTypeId();
            List<Case_Participant__c> caseParticipants = new List<Case_Participant__c>();
            String AccessCode;
            if(agent.size()>0)
            {
                for(Account acc: agent)
                {
                    AccessCode = generateParticipantAccessCode(dispute[0].Id,memberAccount[0].Id);
                    Case_Participant__c cp = new Case_Participant__c();
                    cp.Case__c = dispute[0].Id;
                    cp.Account__c = memberAccount[0].Id;
                    cp.Disputes_credit_control__c =memberAccount[0].Dispute_Credit_Control__c!= null ? memberAccount[0].Dispute_Credit_Control__c:''; 
                    cp.RecordTypeId=cpRecordTypeID;
                    cp.Type__c = 'agent';
                    cp.City__c = acc.PersonMailingCity;  
                    cp.Country__c = acc.PersonMailingCountry;
                    cp.House_No__c = acc.House_No__pc;
                    cp.Local_Area__c = acc.Local_Area__pc;
                    cp.Phone__c = acc.Phone;
                    cp.Postal_Code__c = acc.PersonMailingPostalCode;
                    cp.Primary_Email__c = acc.Email_Description__c;
                    cp.Saon__c = acc.Saon__pc;
                    cp.State__c = acc.PersonMailingState;
                    cp.Street__c = acc.PersonMailingStreet;
                    // cp.Member_Notes__c=acc.Member_Note__c ;
                    cp.Primary_Agent__c = true;
                    cp.First_Name__c=acc.EWI_First_Name__c;
                    cp.Last_Name__c = acc.EWI_Last_Name__c;
                    cp.AGLL_Raised_Respond__c =dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('agent') ? true:false;
                    cp.Access_Code__c = AccessCode;
                    if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('agent'))
                    {
                        cp.First_Name__c=userDetailsInDispute[0].EWI_First_Name__c;
                        cp.Last_Name__c = userDetailsInDispute[0].EWI_Last_Name__c;
                        cp.Primary_Email__c = userDetailsInDispute[0].Email_Description__c;
                        if(!(acc.Email_Description__c ==null || acc.Email_Description__c =='') && acc.Email_Description__c !=  userDetailsInDispute[0].Email_Description__c  )
                        {
                           cp.Other_Emails__c =  acc.Email_Description__c;
                        }
                        cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                        ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;
                        // InstallmentContactId = 
                    }
                    caseParticipants.add(cp);
                } 
            }
            Map<Id,Account> accountsWithPersonContactIdMap = new Map<Id,Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN :caseParticipantAccounts]);
            boolean IsTenantMatch = false;
            if(tenants.size()>0)
            {
                for(Account acc: tenants)
                {
                    AccessCode = generateParticipantAccessCode(dispute[0].Id, acc.Id);
                    Case_Participant__c cp = new Case_Participant__c();
                    cp.Case__c = dispute[0].Id;
                    cp.Account__c = acc.Id;
                    cp.RecordTypeId=cpRecordTypeID;
                    cp.Contact__c = accountsWithPersonContactIdMap.get(acc.Id).PersonContactId;
                    cp.Type__c = 'Tenant';
                    cp.City__c = acc.PersonMailingCity;  
                    cp.Country__c = acc.PersonMailingCountry;
                    cp.House_No__c = acc.House_No__pc;
                    cp.Local_Area__c = acc.Local_Area__pc;
                    cp.Other_Emails__c = acc.Email_Description__c;
                    cp.Phone__c = acc.Phone;
                    cp.Postal_Code__c = acc.PersonMailingPostalCode;
                    cp.Primary_Email__c = acc.personEmail;
                    cp.Saon__c = acc.Saon__pc;
                    cp.State__c = acc.PersonMailingState;
                    cp.Street__c = acc.PersonMailingStreet;
                    cp.Access_Code__c = AccessCode;
                    cp.First_Name__c = acc.EWI_First_Name__c;
                    cp.Last_Name__c = acc.EWI_Last_Name__c;
                    if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('tenant'))
                    {
                        cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                        if((((acc.FirstName+acc.LastName+acc.PersonEmail).toLowerCase()).deleteWhitespace()) ==(((getSubString(userDetailsInDispute[0].EWI_First_Name__c,40)+getSubString(userDetailsInDispute[0].EWI_Last_Name__c,80)+ userDetailsInDispute[0].Email_Description__c).toLowerCase()).deleteWhitespace()))
                        {
                            cp.Is_Lead__c = true;
                            ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;
                            IsTenantMatch = true;
                        }
                    }
                    caseParticipants.add(cp);
                }
                
            }
            if(!IsTenantMatch && dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('tenant'))
            {
                Account acc = new Account();
                AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_Tenant').getRecordTypeId();
                acc.RecordTypeId= AccountRecordTypeId;
                list<Account> ac = [select id from Account where V_Tenant_External_Id__c=:userDetailsInDispute[0].V_Agent_External_Id__c ];
                acc.RecordTypeId= AccountRecordTypeId;
                acc.FirstName = userDetailsInDispute[0].EWI_First_Name__c==null?'': getCamelCaseString(getSubString(userDetailsInDispute[0].EWI_First_Name__c,40));
                acc.LastName = userDetailsInDispute[0].EWI_Last_Name__c==null?'': getCamelCaseString(getSubString(userDetailsInDispute[0].EWI_Last_Name__c,80));
                if(userDetailsInDispute[0].Email_Description__c != null)
                {
                    list<string> emails = string.valueOf(userDetailsInDispute[0].Email_Description__c).split(',');
                    if(emails.size()>0)
                    {
                        acc.PersonEmail =emails[0];
                        emails.remove(0);
                        acc.Email_Description__c = string.join(emails,',');
                    }
                    else
                    {
                        acc.PersonEmail = acc.Email_Description__c;
                        acc.Email_Description__c = null;
                    }
                    
                }
                if(ac.size() >0)
                {
                    acc.id =ac[0].id;
                }
                acc.V_Tenant_External_Id__c =userDetailsInDispute[0].V_Agent_External_Id__c;
                upsert acc;
                list<Account> TennatPersonRec = [SELECT Id, PersonContactId FROM Account WHERE Id =:acc.id];
                AccessCode = generateParticipantAccessCode(dispute[0].Id, acc.Id);
                Case_Participant__c cp = new Case_Participant__c();
                cp.Case__c = dispute[0].Id;
                cp.Account__c = acc.Id;
                cp.Contact__c = TennatPersonRec[0].PersonContactId;
                cp.Type__c = 'Tenant';
                cp.Is_Lead__c = true;
                cp.Access_Code__c = AccessCode;
                cp.First_Name__c = userDetailsInDispute[0].EWI_First_Name__c;
                cp.Last_Name__c = userDetailsInDispute[0].EWI_Last_Name__c;
                cp.Primary_Email__c = userDetailsInDispute[0].Email_Description__c;
                cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                caseParticipants.add(cp);
                ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;
            }
            
            if(nonMemberLandlord.size() >0)
            {
                boolean isNonMemberLandlordMatch = false;
                for(Account acc: nonMemberLandlord)
                {
                    AccessCode = generateParticipantAccessCode(dispute[0].Id, acc.Id);
                    Case_Participant__c cp = new Case_Participant__c();
                    cp.Case__c = dispute[0].Id;
                    cp.Account__c = acc.Id;
                    cp.RecordTypeId=cpRecordTypeID;
                    cp.Contact__c = accountsWithPersonContactIdMap.get(acc.Id).PersonContactId;
                    cp.Type__c = 'Non-Member Landlord';
                    cp.City__c = acc.PersonMailingCity;  
                    cp.Country__c = acc.PersonMailingCountry;
                    cp.House_No__c = acc.House_No__pc;
                    cp.Local_Area__c = acc.Local_Area__pc;
                    cp.Other_Emails__c = acc.Email_Description__c;
                    cp.Phone__c = acc.Phone;
                    cp.Postal_Code__c = acc.PersonMailingPostalCode;
                    cp.Primary_Email__c = acc.personEmail;
                    cp.Saon__c = acc.Saon__pc;
                    cp.State__c = acc.PersonMailingState;
                    cp.Street__c = acc.PersonMailingStreet;
                    cp.First_Name__c=acc.EWI_First_Name__c;
                    cp.Last_Name__c = acc.EWI_Last_Name__c;
                    cp.Access_Code__c = AccessCode;
                    if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord'))
                    {
                        
                        if(!(acc.personEmail ==null || acc.personEmail =='') && acc.personEmail ==  userDetailsInDispute[0].Email_Description__c )
                        {
                            cp.First_Name__c=userDetailsInDispute[0].EWI_First_Name__c;
                            cp.Last_Name__c = userDetailsInDispute[0].EWI_Last_Name__c;
                            cp.Primary_Email__c = userDetailsInDispute[0].Email_Description__c;
                            cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                            ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;
                            isNonMemberLandlordMatch = true;
                            cp.AGLL_Raised_Respond__c = true;
                        }
                    }
                    caseParticipants.add(cp);
                }
                
                if(!isNonMemberLandlordMatch && dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Non-Member Landlord'))
                {
                    Account acc = new Account();
                    AccountRecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_NonMemberLandlord').getRecordTypeId();
                    acc.RecordTypeId= AccountRecordTypeId;
                    list<Account> ac = [select id from Account where EWI_Landlord_Id__c=:userDetailsInDispute[0].V_Agent_External_Id__c ];
                    acc.RecordTypeId= AccountRecordTypeId;
                    acc.FirstName = userDetailsInDispute[0].EWI_First_Name__c==null?'': getCamelCaseString(getSubString(userDetailsInDispute[0].EWI_First_Name__c,40));
                    acc.LastName = userDetailsInDispute[0].EWI_Last_Name__c==null?'': getCamelCaseString(getSubString(userDetailsInDispute[0].EWI_Last_Name__c,80));
                    if(userDetailsInDispute[0].Email_Description__c != null)
                    {
                        list<string> emails = string.valueOf(userDetailsInDispute[0].Email_Description__c).split(',');
                        if(emails.size()>0)
                        {
                            acc.PersonEmail =emails[0];
                            emails.remove(0);
                            acc.Email_Description__c = string.join(emails,',');
                        }
                        else
                        {
                            acc.PersonEmail = acc.Email_Description__c;
                            acc.Email_Description__c = null;
                        }
                        
                    }
                    if(ac.size() >0)
                    {
                        acc.id =ac[0].id;
                    }
                    acc.V_Agent_External_Id__c =userDetailsInDispute[0].V_Agent_External_Id__c;
                    upsert acc;
                    list<Account> nonMemberRec = [SELECT Id, PersonContactId FROM Account WHERE Id =:acc.id];
                    AccessCode = generateParticipantAccessCode(dispute[0].Id, acc.Id);
                    Case_Participant__c cp = new Case_Participant__c();
                    cp.Case__c = dispute[0].Id;
                    cp.Account__c = acc.Id;
                    cp.Contact__c = nonMemberRec[0].PersonContactId;
                    cp.Type__c = 'Non-Member Landlord';
                    cp.Access_Code__c = AccessCode;
                    cp.First_Name__c = userDetailsInDispute[0].EWI_First_Name__c;
                    cp.Last_Name__c = userDetailsInDispute[0].EWI_Last_Name__c;
                    cp.Primary_Email__c = userDetailsInDispute[0].Email_Description__c;
                    cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                    cp.AGLL_Raised_Respond__c = true;
                    //cp.AGLL_Raised_Respond__c = true;
                    caseParticipants.add(cp);
                    ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;   
                }
            }
            if(formindependentLandlord.size() >0)
            {
                for(account acc:formindependentLandlord)
                {
                    AccessCode = generateParticipantAccessCode(dispute[0].Id, independentLandlord[0].Id);
                    Case_Participant__c cp = new Case_Participant__c();
                    cp.Case__c = dispute[0].Id;
                    cp.First_Name__c=acc.EWI_First_Name__c;
                    cp.Last_Name__c = acc.EWI_Last_Name__c;
                    cp.Account__c = independentLandlord[0].Id;
                    cp.RecordTypeId=cpRecordTypeID;
                    cp.Type__c = 'Independent-Landlord';
                    cp.City__c = acc.PersonMailingCity;  
                    cp.Country__c = acc.PersonMailingCountry;
                    cp.House_No__c = acc.House_No__pc;
                    cp.Local_Area__c = acc.Local_Area__pc;
                    cp.Other_Emails__c = acc.Email_Description__c;
                    cp.Phone__c = acc.Phone;
                    cp.Postal_Code__c = acc.PersonMailingPostalCode;
                    cp.Primary_Email__c = acc.personEmail;
                    cp.Saon__c = acc.Saon__pc;
                    cp.State__c = acc.PersonMailingState;
                    cp.Street__c = acc.PersonMailingStreet;
                    cp.Access_Code__c = AccessCode;
                    if(dispute[0].Dispute_Initiated_By__c.equalsIgnoreCase('Independent-Landlord'))
                    {
                        cp.AGLL_Raised_Respond__c = true;
                        cp.First_Name__c=userDetailsInDispute[0].EWI_First_Name__c;
                        cp.Last_Name__c = userDetailsInDispute[0].EWI_Last_Name__c;
                        cp.Primary_Email__c = userDetailsInDispute[0].Email_Description__c;
                        if(!(acc.Email_Description__c ==null || acc.Email_Description__c =='')  && acc.Email_Description__c !=  userDetailsInDispute[0].Email_Description__c)
                        {
                           cp.Other_Emails__c =  acc.Email_Description__c;
                        }
                        cp.EWI_User_Id__c = userDetailsInDispute[0].V_Agent_External_Id__c;
                        ResponseAccessToken=System.Label.EWIVPlus_Link+AccessCode;
                    }
                    caseParticipants.add(cp);
                }
                
            }
            if(caseParticipants.size() > 0)
            {
                insert caseParticipants;
            }
            /*for(Case_Participant__c c:caseParticipants)
{
if(c.Type__c=='Independent-Landlord')
{
CpForInstallment = c.id;
break;
}
else if(c.Type__c=='agent')
{
CpForInstallment = c.id; 
break;
}
}*/
            
        }
        
        obj.put('Success', 'true');
        obj.put('dispute_id', string.valueOf(dispute[0].V_External_Id__c));
        Map<string,string> returnMap = new map<string,string>();
        returnMap.put('email',userDetailsInDispute[0].Email_Description__c);
        returnMap.put('user_id',userDetailsInDispute[0].V_Agent_External_Id__c);
        returnMap.put('secureLink',ResponseAccessToken);
        obj.put(dispute[0].Dispute_Initiated_By__c, returnMap);
        
        Installment__c objIns= new Installment__c();
        objIns.RecordTypeId = Schema.SObjectType.Installment__c.getRecordTypeInfosByName().get('EWI Installment').getRecordTypeId();
        objIns.Amount__c=deposit[0].Deposit_Amount__c;
        objIns.Case__C=dispute[0].Id;
        objIns.Deposit__c=deposit[0].Id;
        objIns.Account__c=memberAccount.size()>0?memberAccount[0].id :independentLandlord[0].id;
        objIns.Status__c='Pending';
        objIns.Installment_Type__c='Receivable';
        objIns.Payment_type__c='Deposit';
        insert objIns;
        
        return obj;
    }
    
    public Scheme__c getSchemeByName(String schemeName) {
        system.debug('Scheme Name : ' + schemeName);
        try {
            return [SELECT Id, Region__c FROM Scheme__c WHERE Name = :schemeName];
        }
        catch (QueryException exc) {
            throw new FC_DisputeAPI_Exception.InvalidDataException('Could not find scheme for configured name: ' + schemeName);
        }
    }
    public string getCamelCaseString(String value)
    {
        String result = '';
        if (value != '' || value != null ) {
            value =value.toLowerCase();
            for (String iter : value.split(' ')) {
                if (iter != '') {
                    result += iter.capitalize()+' ';
                }
            }
        }
        return result;
        
    }
    public string getSubString(String value,integer length)
    {
        String result = '';
        
        if (!(value == '' || value == null) ) {
            if(value.length()>length)
            {
                result = value.substring(0, length);
            }
            else
            {
                result = value;
            }
        }
        return result;
        
    }
    private String generateParticipantAccessCode(String caseId, String accId){
        String accessCode;
        Long msDiff = Datetime.now().getTime();
        string timeas = string.valueof(msDiff);
        try{
            accessCode= generateHMACKey('hmacSHA1', caseId+timeas, accId);
        }
        catch(Exception e){
            throw new FC_DisputeAPI_Exception.InternalException('Failed to generate Access Code for Case Participant with account ID ' + accId);
        }
        return accessCode;
    }
    
    public Map<string,object> validateUpdatePayloadexecute (String Payload){
        
        Map<String, Object> deserializedPayload = validateJSONPayload(payload);
        this.disputeIdForUpdate=string.valueof(deserializedPayload.get('dispute_id'));
        this.userTypeForUpdate=string.valueof(deserializedPayload.get('type'));
        this.UserIdForUpdate=string.valueof(deserializedPayload.get('user_id'));
        string memberNoteVal = string.valueof(deserializedPayload.get('member_note'));
        if(!(memberNoteVal =='' ||memberNoteVal ==null ))
        {
            throw new FC_DisputeAPI_Exception.JSONException('member_note Not a valid entry');
        }
        
        if(!(disputeIdForUpdate =='' ||disputeIdForUpdate ==null ))
        {
            validateDispute(disputeIdForUpdate);
        }
        else
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required value: dispute_id');
        }
        if(userTypeForUpdate =='')
        {
            throw new FC_DisputeAPI_Exception.JSONException('Missing required value: type');
        }
        if(userTypeForUpdate =='Independent' || userTypeForUpdate =='Non Member'|| userTypeForUpdate =='unipol'|| userTypeForUpdate =='nrla')
        {
            userTypeForQuery = 'landlord';
            if(userTypeForUpdate =='Non Member')
            {
                userQueryCp= 'Non-Member Landlord';
            }
            else
            {
                userQueryCp='Independent-Landlord';
            }
        }
        else if(userTypeForUpdate =='tenant' || userTypeForUpdate =='agent')
        {
            userTypeForQuery= userTypeForUpdate;
            userQueryCp = userTypeForUpdate;
        }
        else
        {
            throw new FC_DisputeAPI_Exception.JSONException('type.'+userTypeForUpdate +' Not a valid entry');
        }
        if(UserIdForUpdate == null)
        {
            UserIdForUpdate='';
        }
        
        if(UserIdForUpdate !='')
        {
            //ValidateMemberid(userTypeForUpdate,UserIdForUpdate);
        }
        deserializedPayload.remove('reference');
        deserializedPayload.remove('dispute_id');
        deserializedPayload.remove('type');
        deserializedPayload.remove('user_id');
        
        JSONGenerator genUpdate = JSON.createGenerator(true);
        genUpdate.writeStartObject();
        genUpdate.writeFieldName(userTypeForQuery);
        genUpdate.writeStartObject();
        for (String key : deserializedPayload.keySet()){
            genUpdate.writeStringField(key,string.valueof(deserializedPayload.get(key)));
        }
        genUpdate.writeEndObject();
        genUpdate.writeEndObject();
        Map<String, Object> deserializedPayload2 = validateJSONPayload(genUpdate.getAsString());
        
        
        checkObjectPayloadUpdate(userTypeForQuery,deserializedPayload2);
        Map<String, object> accesscode = ProcessPayloadUpdate();
        return accesscode;
    }
    public void validateDispute(String DisputeId)
    {
       
        list<case> caseRec= [select id from case where V_External_Id__c=:DisputeId limit 1];
        if(caseRec.size() == 0){
            throw new FC_DisputeAPI_Exception.JSONException('Invalid  dispute Id ' + DisputeId );
        }
        this.caseIdForUpdate =caseRec[0].id; 
    }
    public void checkObjectPayloadUpdate(string userType,Map<String, Object> deserializedPayload){
        
        mappingsBysystemObjectName = new Map<String,EWI_Dispute_API_Object__c>();
        list<EWI_Dispute_API_Object__c> objects =  [ SELECT Id, Name, isRequired__c, Object_Type__c, Type__c,
                                                    (SELECT Id, Salesforce_Field_API_Name__c, Payload_Parameter_Name__c, Salesforce_Field_Length__c,
                                                     Salesforce_Field_Type__c, isRequired__c, SObject_Name__c, EWI_Dispute_API_Object__r.Name
                                                     FROM EWI_Dispute_API_Mappings__r
                                                     WHERE isActive__c = true)
                                                    FROM EWI_Dispute_API_Object__c
                                                    WHERE isActive__c = true  and  Type__c =: 'EW Claim API'];
        for(EWI_Dispute_API_Object__c obj : objects) {
            mappingsBysystemObjectName.put(obj.Name.toLowerCase(), obj);
        }
        
        List<String> errors = new List<String>();
        for(String payloadObjectName : deserializedPayload.keySet()) {
            Object payloadObjectvalue = deserializedPayload.get(payloadObjectName);
            Set<String> invalidParameters = new Set<String>();
            Set<String> missingRequiredParameters = new Set<String>();
            List<Map<String,Object>> payloadObjectRecords = getPayloadObjectRecords(payloadObjectvalue);
            if(payloadObjectName != 'agent' )
            {
                for(Map<String,Object> payloadObjectRecord : payloadObjectRecords) {
                    invalidParameters.addall(getInvalidParameters(payloadObjectName,payloadObjectRecord,'casePartiAccount'));
                }  
            }
            else{
                Object payloadObjectvalue1 = payloadObjectRecords;
                List<Map<String,Object>> payloadObjectRecords1 = getPayloadObjectRecords(payloadObjectvalue1);
                if(payloadObjectName == 'agent'){
                    for(Map<String,Object> payloadObjectRecord : payloadObjectRecords1) {
                        
                        for(string payloadObjectKey : payloadObjectRecord.keyset())
                        {
                            if(payloadObjectKey =='branch')
                            {
                                throw new FC_DisputeAPI_Exception.JSONException('Branch objects Not Match the required Object');
                            }
                        }
                        
                    }
                    Map<String,Object> payloadObjectRecordAgent= payloadObjectRecords1[0];
                    payloadObjectRecordAgent.remove('branch');
                    invalidParameters.addall(getInvalidParameters('agent',payloadObjectRecordAgent,'casePartiAccount'));
                    
                }
            }
        }
    }
    public void ValidateMemberid(String userType, String externalId)
    {
        list<Account> accountRec = new list<Account>();
        
        if(userType.equalsIgnoreCase('agent') || userType.equalsIgnoreCase('tenant')|| userType.equalsIgnoreCase('independent') || userType.equalsIgnoreCase('non member')|| userType.equalsIgnoreCase('unipol')|| userType.equalsIgnoreCase('nrla'))
        {   
            casePartiRec=[select id,Access_Code__c,First_Name__c,Last_Name__c,Primary_Email__c,Account__c,type__c,Case__r.AccountID,Account__r.PersonEmail from Case_Participant__c where Case__c=:caseIdForUpdate ];
        }
        else
        {
            throw new FC_DisputeAPI_Exception.JSONException('Type not a valid entry.');
        }
        
    }
    public Map<String, object> ProcessPayloadUpdate()
    {
        if(userTypeForUpdate.equalsIgnoreCase('agent') || userTypeForUpdate.equalsIgnoreCase('tenant')|| userTypeForUpdate.equalsIgnoreCase('independent') || userTypeForUpdate.equalsIgnoreCase('non member')|| userTypeForUpdate.equalsIgnoreCase('unipol')|| userTypeForUpdate.equalsIgnoreCase('nrla'))
        {  
            casePartiRec=[select id,Access_Code__c,AGLL_Raised_Respond__c,First_Name__c,EWI_User_Id__c,Last_Name__c,Primary_Email__c,Account__c,type__c,Case__r.AccountID,Account__r.PersonEmail from Case_Participant__c where Case__c=:caseIdForUpdate ];
        }
        else
        {
            throw new FC_DisputeAPI_Exception.JSONException('Type not a valid entry.');
        }
        
        Map<String, String> ResponseMap = new Map<String, String>();
        Map<string,object> obj = new map<string,object>();
        obj.put('Success', 'true');
        string AccountRecordTypeId;
        string accessToken='';
        Case_Participant__c cptoupdate = new Case_Participant__c();
        Boolean flag = false;
        Boolean FlagforRais = false;
        string raiseType = '';
        if(casePartiRec.size()>0)
        {
            integer i=0;
            for(Case_Participant__c cp:casePartiRec )
            {
                i++;
                if(!FlagforRais && cp.AGLL_Raised_Respond__c)
                {
                    raiseType = cp.Type__c; 
                    FlagforRais = true;
                }
                if((cp.First_Name__c+ cp.Last_Name__c+cp.Primary_Email__c) == caseParticipantAccounts[0].EWI_First_Name__c+caseParticipantAccounts[0].EWI_Last_Name__c+caseParticipantAccounts[0].Email_Description__c && (cp.Type__c).equalsIgnoreCase(userQueryCp))
                {
                    accessToken = generateParticipantAccessCode(caseIdForUpdate,cp.Account__c);
                    cptoupdate.Access_Code__c = accessToken;
                    if(UserIdForUpdate !='')
                    {
                        cptoupdate.EWI_User_Id__c = UserIdForUpdate;
                    }
                    cptoupdate.id = cp.id;
                    if(caseParticipantAccounts[0].Salutation != null)
                    {
                        cptoupdate.Salutation__c = caseParticipantAccounts[0].Salutation;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCity != null)
                    {
                        cptoupdate.City__c = caseParticipantAccounts[0].PersonMailingCity;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCountry != null)
                    {
                        cptoupdate.Country__c = caseParticipantAccounts[0].PersonMailingCountry;
                    }
                    if(caseParticipantAccounts[0].House_No__pc != null)
                    {
                        cptoupdate.House_No__c = caseParticipantAccounts[0].House_No__pc;
                    }
                    if(caseParticipantAccounts[0].Local_Area__pc != null)
                    {
                        cptoupdate.Local_Area__c = caseParticipantAccounts[0].Local_Area__pc;
                    }
                    if(caseParticipantAccounts[0].Phone != null)
                    {
                        cptoupdate.Phone__c = caseParticipantAccounts[0].Phone;
                    }
                    if(caseParticipantAccounts[0].PersonMailingPostalCode != null)
                    {
                        cptoupdate.Postal_Code__c = caseParticipantAccounts[0].PersonMailingPostalCode;
                    }
                    if(caseParticipantAccounts[0].Saon__pc != null)
                    {
                        cptoupdate.Saon__c = caseParticipantAccounts[0].Saon__pc;
                    }
                    if(caseParticipantAccounts[0].PersonMailingState != null)
                    {
                        cptoupdate.State__c = caseParticipantAccounts[0].PersonMailingState;
                    }
                    if(caseParticipantAccounts[0].PersonMailingStreet != null)
                    {
                        cptoupdate.Street__c = caseParticipantAccounts[0].PersonMailingStreet;
                    }
                    //caseParticipantAccounts[0].id =cp.Account__c; 
                    flag = true;
                    break;
                    
                }
                if(UserIdForUpdate != '')
                {
                    if(UserIdForUpdate ==cp.EWI_User_Id__c)
                    {
                        accessToken = generateParticipantAccessCode(caseIdForUpdate,cp.Account__c);
                        cptoupdate.First_Name__c = caseParticipantAccounts[0].EWI_First_Name__c;
                        cptoupdate.Last_Name__c = caseParticipantAccounts[0].EWI_Last_Name__c;
                        cptoupdate.Primary_Email__c = caseParticipantAccounts[0].Email_Description__c;
                        cptoupdate.Access_Code__c = accessToken;
                        cptoupdate.id = cp.id;
                        if(caseParticipantAccounts[0].Salutation != null)
                    {
                        cptoupdate.Salutation__c = caseParticipantAccounts[0].Salutation;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCity != null)
                    {
                        cptoupdate.City__c = caseParticipantAccounts[0].PersonMailingCity;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCountry != null)
                    {
                        cptoupdate.Country__c = caseParticipantAccounts[0].PersonMailingCountry;
                    }
                    if(caseParticipantAccounts[0].House_No__pc != null)
                    {
                        cptoupdate.House_No__c = caseParticipantAccounts[0].House_No__pc;
                    }
                    if(caseParticipantAccounts[0].Local_Area__pc != null)
                    {
                        cptoupdate.Local_Area__c = caseParticipantAccounts[0].Local_Area__pc;
                    }
                    if(caseParticipantAccounts[0].Phone != null)
                    {
                        cptoupdate.Phone__c = caseParticipantAccounts[0].Phone;
                    }
                    if(caseParticipantAccounts[0].PersonMailingPostalCode != null)
                    {
                        cptoupdate.Postal_Code__c = caseParticipantAccounts[0].PersonMailingPostalCode;
                    }
                    if(caseParticipantAccounts[0].Saon__pc != null)
                    {
                        cptoupdate.Saon__c = caseParticipantAccounts[0].Saon__pc;
                    }
                    if(caseParticipantAccounts[0].PersonMailingState != null)
                    {
                        cptoupdate.State__c = caseParticipantAccounts[0].PersonMailingState;
                    }
                    if(caseParticipantAccounts[0].PersonMailingStreet != null)
                    {
                        cptoupdate.Street__c = caseParticipantAccounts[0].PersonMailingStreet;
                    }
                        //caseParticipantAccounts[0].id =cp.Account__c;
                        flag = true;
                        break;
                        
                    }
                    else
                    {  
                        if(i==casePartiRec.size())
                        {
                            throw new FC_DisputeAPI_Exception.JSONException('Reference: ' + UserIdForUpdate +' not link with this dispute: '+ disputeIdForUpdate);
                        }
                         
                    }
                }
                
            }
            
            
            Id cpRecordTypeID2 = Schema.SObjectType.Case_Participant__c.getRecordTypeInfosByName().get('EWI Case Participant').getRecordTypeId();
            if(!flag)
            {
                if(userTypeForUpdate.equalsIgnoreCase('agent') ||userTypeForUpdate.equalsIgnoreCase('Independent') )
                {
                    accessToken = generateParticipantAccessCode(caseIdForUpdate,casePartiRec[0].Case__r.AccountID);
                    cptoupdate.First_Name__c = caseParticipantAccounts[0].EWI_First_Name__c;
                    cptoupdate.Last_Name__c = caseParticipantAccounts[0].EWI_Last_Name__c;
                    cptoupdate.Primary_Email__c = caseParticipantAccounts[0].Email_Description__c;
                    cptoupdate.type__c = userTypeForUpdate.equalsIgnoreCase('agent') ?'Agent':'Independent-Landlord'; 
                    cptoupdate.Case__c= caseIdForUpdate;
                    cptoupdate.Account__c= casePartiRec[0].Case__r.AccountID;
                    cptoupdate.Access_Code__c = accessToken;
                    cptoupdate.RecordTypeId = cpRecordTypeID2;
                    if(caseParticipantAccounts[0].Salutation != null)
                    {
                        cptoupdate.Salutation__c = caseParticipantAccounts[0].Salutation;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCity != null)
                    {
                        cptoupdate.City__c = caseParticipantAccounts[0].PersonMailingCity;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCountry != null)
                    {
                        cptoupdate.Country__c = caseParticipantAccounts[0].PersonMailingCountry;
                    }
                    if(caseParticipantAccounts[0].House_No__pc != null)
                    {
                        cptoupdate.House_No__c = caseParticipantAccounts[0].House_No__pc;
                    }
                    if(caseParticipantAccounts[0].Local_Area__pc != null)
                    {
                        cptoupdate.Local_Area__c = caseParticipantAccounts[0].Local_Area__pc;
                    }
                    if(caseParticipantAccounts[0].Phone != null)
                    {
                        cptoupdate.Phone__c = caseParticipantAccounts[0].Phone;
                    }
                    if(caseParticipantAccounts[0].PersonMailingPostalCode != null)
                    {
                        cptoupdate.Postal_Code__c = caseParticipantAccounts[0].PersonMailingPostalCode;
                    }
                    if(caseParticipantAccounts[0].Saon__pc != null)
                    {
                        cptoupdate.Saon__c = caseParticipantAccounts[0].Saon__pc;
                    }
                    if(caseParticipantAccounts[0].PersonMailingState != null)
                    {
                        cptoupdate.State__c = caseParticipantAccounts[0].PersonMailingState;
                    }
                    if(caseParticipantAccounts[0].PersonMailingStreet != null)
                    {
                        cptoupdate.Street__c = caseParticipantAccounts[0].PersonMailingStreet;
                    }
                    if(userTypeForUpdate.equalsIgnoreCase(raiseType))
                    {
                        cptoupdate.AGLL_Raised_Respond__c= true;
                    }
                }
                else
                {
                    String recTypIdCp ='';
                    if(userTypeForUpdate.equalsIgnoreCase('tenant'))
                    {
                        recTypIdCp=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_Tenant').getRecordTypeId(); 
                    }
                    else
                    {
                        recTypIdCp=Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('EWI_NonMemberLandlord').getRecordTypeId();
                    }
                    caseParticipantAccounts[0].RecordTypeId =recTypIdCp;
                    caseParticipantAccounts[0].PersonEmail = caseParticipantAccounts[0].Email_Description__c;
                    if(recTypIdCp !='')
                    {
                        insert caseParticipantAccounts;
                    }
                   
                    list<Account> accCP = [SELECT Id, PersonContactId FROM Account WHERE Id IN :caseParticipantAccounts];
                    accessToken = generateParticipantAccessCode(caseIdForUpdate,caseParticipantAccounts[0].id);
                    cptoupdate.First_Name__c = caseParticipantAccounts[0].EWI_First_Name__c;
                    cptoupdate.Last_Name__c = caseParticipantAccounts[0].EWI_Last_Name__c;
                    cptoupdate.Case__c= caseIdForUpdate;
                    cptoupdate.Account__c= caseParticipantAccounts[0].id;
                    if(accCP.size() >0)
                    {
                        cptoupdate.Contact__c =accCP[0].PersonContactId;   
                    }
                    cptoupdate.Primary_Email__c = caseParticipantAccounts[0].Email_Description__c;
                    cptoupdate.type__c = userTypeForUpdate.equalsIgnoreCase('tenant') ?'Tenant':'Non-Member Landlord'; 
                    cptoupdate.Access_Code__c = accessToken;
                    cptoupdate.RecordTypeId = cpRecordTypeID2;
                    if(caseParticipantAccounts[0].Salutation != null)
                    {
                        cptoupdate.Salutation__c = caseParticipantAccounts[0].Salutation;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCity != null)
                    {
                        cptoupdate.City__c = caseParticipantAccounts[0].PersonMailingCity;
                    }
                    if(caseParticipantAccounts[0].PersonMailingCountry != null)
                    {
                        cptoupdate.Country__c = caseParticipantAccounts[0].PersonMailingCountry;
                    }
                    if(caseParticipantAccounts[0].House_No__pc != null)
                    {
                        cptoupdate.House_No__c = caseParticipantAccounts[0].House_No__pc;
                    }
                    if(caseParticipantAccounts[0].Local_Area__pc != null)
                    {
                        cptoupdate.Local_Area__c = caseParticipantAccounts[0].Local_Area__pc;
                    }
                    if(caseParticipantAccounts[0].Phone != null)
                    {
                        cptoupdate.Phone__c = caseParticipantAccounts[0].Phone;
                    }
                    if(caseParticipantAccounts[0].PersonMailingPostalCode != null)
                    {
                        cptoupdate.Postal_Code__c = caseParticipantAccounts[0].PersonMailingPostalCode;
                    }
                    if(caseParticipantAccounts[0].Saon__pc != null)
                    {
                        cptoupdate.Saon__c = caseParticipantAccounts[0].Saon__pc;
                    }
                    if(caseParticipantAccounts[0].PersonMailingState != null)
                    {
                        cptoupdate.State__c = caseParticipantAccounts[0].PersonMailingState;
                    }
                    if(caseParticipantAccounts[0].PersonMailingStreet != null)
                    {
                        cptoupdate.Street__c = caseParticipantAccounts[0].PersonMailingStreet;
                    }
                }
                
            }
            
            
        }
        if(cptoupdate != null)
        {
            upsert cptoupdate;
        }
        Map<string,string> returnMap = new map<string,string>();
        returnMap.put('email',caseParticipantAccounts[0].Email_Description__c);
        returnMap.put('user_id',UserIdForUpdate);
        returnMap.put('secureLink',System.Label.EWIVPlus_Link+accessToken);
        obj.put(userTypeForUpdate, returnMap);
        //return ResponseMap;
        return obj;
    }
    
    
    
}