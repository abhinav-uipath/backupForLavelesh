public class EI_SDS_MileStone {
    @AuraEnabled
    public static case getCaseDetails(string recordId)
    {
        
        case casedetails = [select id,status,Days_Remaining__c,
                            Agent_landlord_responded_on_adjudication__c,Tenant_responded_on_adjudication__c,
                            Tenant_remaining_adjudication_days__c,Agent_landlord_remain_adjudication_days__c
                            from case where Id=:recordId];
        return casedetails;
    
}	
}