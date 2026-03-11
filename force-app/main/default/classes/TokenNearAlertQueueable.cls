public class TokenNearAlertQueueable implements Queueable {

    private List<Id> tokenIds;

    public TokenNearAlertQueueable(List<Id> tokenIds) {
        this.tokenIds = tokenIds;
    }

    public void execute(QueueableContext context) {

        List<Token__c> tokens = [
            SELECT Id, Email__c, Name,
                   Token_Number__c,
                   Position_In_Queue__c,
                   Near_Alert_Sent__c
            FROM Token__c
            WHERE Id IN :tokenIds
        ];

        List<Messaging.SingleEmailMessage> emails =
            new List<Messaging.SingleEmailMessage>();

        List<Token__c> tokensToUpdate =
            new List<Token__c>();

        for (Token__c t : tokens) {

            Messaging.SingleEmailMessage mail =
                new Messaging.SingleEmailMessage();

            mail.setToAddresses(new List<String>{ t.Email__c });
            mail.setSubject('SmartQueue – Your Turn is Near!');
            mail.setPlainTextBody(
                'Hello ' + t.Name + ',\n\n' +
                'Your token number: ' + t.Token_Number__c + '\n' +
                'Current Position: ' + t.Position_In_Queue__c + '\n\n' +
                'Please be ready. Your turn is coming soon.\n\n' +
                'SmartQueue System'
            );

            emails.add(mail);

            t.Near_Alert_Sent__c = true;
            tokensToUpdate.add(t);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        if (!tokensToUpdate.isEmpty()) {
            update tokensToUpdate;
        }
    }
}