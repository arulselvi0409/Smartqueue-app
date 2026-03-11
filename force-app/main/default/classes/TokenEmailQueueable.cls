public class TokenEmailQueueable implements Queueable {

    private List<Id> tokenIds;

    public TokenEmailQueueable(List<Id> tokenIds) {
        this.tokenIds = tokenIds;
    }

    public void execute(QueueableContext context) {

        List<Token__c> tokens = [
            SELECT Id,
                   Email__c,
                   Token_Number__c,
                   Position_In_Queue__c,
                   Estimated_Wait_Time__c,
                   Confirmation_Email_Sent__c
            FROM Token__c
            WHERE Id IN :tokenIds
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Token__c> tokensToUpdate = new List<Token__c>();

        for (Token__c token : tokens) {

            if (!token.Confirmation_Email_Sent__c && token.Email__c != null) {

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{token.Email__c});
                mail.setSubject('SmartQueue Token Confirmation');
                mail.setPlainTextBody(
                    'Hello,\n\n' +
                    'Your Token Number: ' + token.Token_Number__c +
                    '\nCurrent Position: ' + token.Position_In_Queue__c +
                    '\nEstimated Wait Time: ' + token.Estimated_Wait_Time__c + ' minutes' +
                    '\n\nThank you for using SmartQueue.'
                );

                emails.add(mail);

                token.Confirmation_Email_Sent__c = true;
                tokensToUpdate.add(token);
            }
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }

        if (!tokensToUpdate.isEmpty()) {
            update tokensToUpdate;
        }
    }
}