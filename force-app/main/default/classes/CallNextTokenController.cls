public with sharing class CallNextTokenController {

    @AuraEnabled
    public static void callNextToken(Id centerId) {

        // Step 1: Complete current token
        List<Token__c> currentServing = [
            SELECT Id
            FROM Token__c
            WHERE Service_Center__c = :centerId
            AND Status__c = 'In Progress'
            LIMIT 1
        ];

        if(!currentServing.isEmpty()){
            currentServing[0].Status__c = 'Completed';
            update currentServing[0];
        }

        // Step 2: Get next waiting token
        List<Token__c> nextToken = [
            SELECT Id, Status__c
            FROM Token__c
            WHERE Service_Center__c = :centerId
            AND Status__c = 'Waiting'
            ORDER BY Position_In_Queue__c ASC
            LIMIT 1
        ];

        if(!nextToken.isEmpty()){
            nextToken[0].Status__c = 'In Progress';
            update nextToken[0];
        }

    }
}