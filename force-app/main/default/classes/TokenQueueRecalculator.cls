public class TokenQueueRecalculator {

    public static void recalculateQueue(List<Token__c> updatedTokens){

        Set<Id> centerIds = new Set<Id>();

        // Collect affected service centers
        for(Token__c t : updatedTokens){
            if(t.Status__c == 'Completed' || t.Status__c == 'Cancelled'){
                if(t.Service_Center__c != null){
                    centerIds.add(t.Service_Center__c);
                }
            }
        }

        if(centerIds.isEmpty()) return;

        for(Id centerId : centerIds){

            // Get all waiting tokens ordered by CreatedDate
            List<Token__c> waitingTokens = [
                SELECT Id,
                       Position_In_Queue__c,
                       Estimated_Wait_Time__c,
                       Near_Alert_Sent__c,
                       Email__c,
                       Token_Number__c,
                       Name
                FROM Token__c
                WHERE Service_Center__c = :centerId
                AND Status__c = 'Waiting'
                ORDER BY CreatedDate ASC
            ];

            // Get service center details
            Service_Center__c center = [
                SELECT Avg_Service_Time__c, Total_Counters__c
                FROM Service_Center__c
                WHERE Id = :centerId
                LIMIT 1
            ];

            Integer position = 1;

            for(Token__c token : waitingTokens){

                token.Position_In_Queue__c = position;

                if(center.Avg_Service_Time__c != null &&
                   center.Total_Counters__c != null &&
                   center.Total_Counters__c > 0){

                    Decimal estimatedWait =
                        (position * center.Avg_Service_Time__c)
                        / center.Total_Counters__c;

                    token.Estimated_Wait_Time__c =
                        Integer.valueOf(estimatedWait);
                }

                // 🔥 Near Alert Logic (Using Email__c)
                if(position <= 5 &&
                   (token.Near_Alert_Sent__c == null ||
                    token.Near_Alert_Sent__c == false) &&
                   token.Email__c != null){

                    Messaging.SingleEmailMessage mail =
                        new Messaging.SingleEmailMessage();

                    mail.setToAddresses(
                        new String[] { token.Email__c }
                    );

                    mail.setSubject(
                        'SmartQueue Alert - You Are Almost There'
                    );

                    mail.setPlainTextBody(
                        'Hello ' + token.Name + ',\n\n' +
                        'Your Token Number: ' + token.Token_Number__c + '\n' +
                        'Current Position: ' + position + '\n' +
                        'Estimated Wait Time: ' +
                        token.Estimated_Wait_Time__c + ' minutes\n\n' +
                        'Please be ready. You are now within the top 5 in queue.\n\n' +
                        'SmartQueue System'
                    );

                    Messaging.sendEmail(
                        new Messaging.SingleEmailMessage[] { mail }
                    );

                    token.Near_Alert_Sent__c = true;
                }

                position++;
            }

            if(!waitingTokens.isEmpty()){
                update waitingTokens;
            }
        }
    }
}