public class TokenNumberGenerator {

    public static void generateTokenNumbers(List<Token__c> tokens) {

        Set<Id> centerIds = new Set<Id>();

        for(Token__c t : tokens){
            if(t.Service_Center__c != null){
                centerIds.add(t.Service_Center__c);
            }
        }

        Map<Id, Service_Center__c> centerMap = new Map<Id, Service_Center__c>(
            [
                SELECT Id, Name, Type__c, Avg_Service_Time__c, Total_Counters__c
                FROM Service_Center__c
                WHERE Id IN :centerIds
            ]
        );

        for(Token__c t : tokens){

            if(t.Service_Center__c == null || !centerMap.containsKey(t.Service_Center__c)){
                continue;
            }

            Service_Center__c center = centerMap.get(t.Service_Center__c);

            /* TOKEN PREFIX */

            String typeValue = center.Type__c != null ? center.Type__c.trim().toLowerCase() : '';

            String prefix;

            if(typeValue == 'clinic'){
                prefix = 'CLI-';
            }
            else if(typeValue == 'ration'){
                prefix = 'RAT-';
            }
            else if(typeValue == 'parlor'){
                prefix = 'PAR-';
            }
            else if(typeValue == 'govtoffice'){
                prefix = 'GOV-';
            }
            else{
                prefix = 'GEN-';
            }

            /* TOKEN NUMBER */

            Integer countTokens = [
                SELECT COUNT()
                FROM Token__c
                WHERE Service_Center__c = :t.Service_Center__c
            ];

            Integer nextNumber = countTokens + 1;

            String formattedNumber;

            if(nextNumber < 10){
                formattedNumber = '00' + nextNumber;
            }
            else if(nextNumber < 100){
                formattedNumber = '0' + nextNumber;
            }
            else{
                formattedNumber = String.valueOf(nextNumber);
            }

            t.Token_Number__c = prefix + formattedNumber;

            /* QUEUE POSITION */

            Integer waitingCount = [
                SELECT COUNT()
                FROM Token__c
                WHERE Service_Center__c = :t.Service_Center__c
                AND Status__c = 'Waiting'
            ];

            t.Position_In_Queue__c = waitingCount + 1;

            /* ESTIMATED WAIT TIME */

            if(center.Avg_Service_Time__c != null &&
               center.Total_Counters__c != null &&
               center.Total_Counters__c > 0){

                Decimal estimatedWait =
                (t.Position_In_Queue__c * center.Avg_Service_Time__c)
                / center.Total_Counters__c;

                t.Estimated_Wait_Time__c = Integer.valueOf(estimatedWait);
            }

            /* QR CODE GENERATION */

            String qrData =
'SmartQueue Token\n\n' +
'Name: ' + t.Name + '\n' +
'Token Number: ' + t.Token_Number__c + '\n' +
'Service Center: ' + center.Name + '\n' +
'Queue Position: ' + t.Position_In_Queue__c;

String encodedData = EncodingUtil.urlEncode(qrData, 'UTF-8');

t.QR_Code_URL__c =
'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=' + encodedData;


            /* EMAIL NOTIFICATION */

            if(t.Email__c != null && t.Confirmation_Email_Sent__c == false){

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                mail.setToAddresses(new String[] { t.Email__c });

                mail.setSubject('SmartQueue Token Confirmation');

                mail.setHtmlBody(

                    '<h2>Hello ' + t.Name + ',</h2>' +

                    '<h3>SmartQueue Token Confirmation</h3>' +

                    '<p><b>Token Number:</b> ' + t.Token_Number__c + '</p>' +
                    '<p><b>Service Center:</b> ' + center.Name + '</p>' +
                    '<p><b>Queue Position:</b> ' + t.Position_In_Queue__c + '</p>' +
                    '<p><b>Estimated Wait Time:</b> ' + t.Estimated_Wait_Time__c + ' minutes</p>' +

                    '<p><b>Show this QR code at the service center:</b></p>' +

                    '<img src="' + t.QR_Code_URL__c + '" width="250" height="250" style="border:1px solid #ccc;" />' +

                    '<br/><br/>' +

                    '<p>You have successfully joined the queue.</p>' +

                    '<p>Thank you for using SmartQueue.</p>' +

                    '<p><b>~ SmartQueue System</b></p>'
                );

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

                t.Confirmation_Email_Sent__c = true;
            }

        }
    }
}