public class TokenNearAlertService {

    public static List<Id> getNearAlertTokenIds(
        List<Token__c> newList,
        Map<Id, Token__c> oldMap
    ) {

        List<Id> eligibleTokenIds = new List<Id>();

        for (Token__c t : newList) {

            Boolean shouldSendAlert = false;

            // CASE 1 — INSERT scenario (oldMap is null)
            if (oldMap == null) {

                if (t.Position_In_Queue__c <= 5 &&
                    !t.Near_Alert_Sent__c &&
                    t.Email__c != null) {

                    shouldSendAlert = true;
                }
            }

            // CASE 2 — UPDATE scenario (position moved)
            else if (oldMap.containsKey(t.Id)) {

                Token__c oldToken = oldMap.get(t.Id);

                if (t.Position_In_Queue__c != oldToken.Position_In_Queue__c &&
                    t.Position_In_Queue__c <= 5 &&
                    !t.Near_Alert_Sent__c &&
                    t.Email__c != null) {

                    shouldSendAlert = true;
                }
            }

            if (shouldSendAlert) {
                eligibleTokenIds.add(t.Id);
            }
        }

        return eligibleTokenIds;
    }
}