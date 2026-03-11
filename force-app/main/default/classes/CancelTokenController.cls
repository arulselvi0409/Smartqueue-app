public with sharing class CancelTokenController {

    @AuraEnabled
    public static void cancelToken(Id tokenId){

        Token__c token = [
            SELECT Id, Status__c
            FROM Token__c
            WHERE Id = :tokenId
        ];

        token.Status__c = 'Cancelled';

        update token;
    }
}