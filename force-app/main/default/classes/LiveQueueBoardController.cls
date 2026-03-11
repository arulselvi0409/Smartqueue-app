public with sharing class LiveQueueBoardController {

    @AuraEnabled(cacheable=true)
    public static List<Token__c> getLiveQueue(Id serviceCenterId){

        return [
            SELECT Id, Token_Number__c, Status__c, Position_In_Queue__c
            FROM Token__c
            WHERE Service_Center__c = :serviceCenterId
            AND Status__c = 'Waiting'
            ORDER BY Position_In_Queue__c ASC
            LIMIT 5
        ];

    }

}