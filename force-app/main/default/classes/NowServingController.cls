public with sharing class NowServingController {

    @AuraEnabled(cacheable=true)
    public static Token__c getNowServingToken(Id centerId) {

        List<Token__c> tokens = [
            SELECT Id, Token_Number__c
            FROM Token__c
            WHERE Service_Center__c = :centerId
            AND Status__c = 'In Progress'
            LIMIT 1
        ];

        if(tokens.isEmpty()){
            return null;
        }

        return tokens[0];
    }
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getQueueDisplay(Id serviceCenterId){

    Map<String, Object> result = new Map<String, Object>();

    Token__c serving = [
        SELECT Token_Number__c
        FROM Token__c
        WHERE Service_Center__c = :serviceCenterId
        AND Status__c = 'In Progress'
        LIMIT 1
    ];

    List<Token__c> next = [
        SELECT Token_Number__c
        FROM Token__c
        WHERE Service_Center__c = :serviceCenterId
        AND Status__c = 'Waiting'
        ORDER BY Position_In_Queue__c
        LIMIT 3
    ];

    result.put('nowServing', serving != null ? serving.Token_Number__c : '---');
    result.put('nextTokens', next);

    return result;
}
}