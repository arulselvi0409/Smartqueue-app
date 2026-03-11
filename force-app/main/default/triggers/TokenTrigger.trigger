trigger TokenTrigger on Token__c (
    before insert,
    after insert,
    after update
) {

    /* BEFORE INSERT
       Generate token numbers, position, wait time */
    if (Trigger.isBefore && Trigger.isInsert) {
        TokenNumberGenerator.generateTokenNumbers(Trigger.new);
    }


    /* AFTER INSERT
       Queue recalculation
       Email confirmation
       Near alert check */
    if (Trigger.isAfter && Trigger.isInsert) {

        // Recalculate queue
        TokenQueueRecalculator.recalculateQueue(Trigger.new);

        // Collect token IDs for async processing
        Set<Id> tokenIds = new Set<Id>();

        for (Token__c t : Trigger.new) {
            if (t.Email__c != null) {
                tokenIds.add(t.Id);
            }
        }

        // Send confirmation email
        if (!tokenIds.isEmpty()) {
            System.enqueueJob(
                new TokenEmailQueueable(new List<Id>(tokenIds))
            );
        }

        // 🔹 NEW: Run near alert check for newly created tokens
        List<Id> nearAlertIds =
            TokenNearAlertService.getNearAlertTokenIds(
                Trigger.new,
                null
            );

        if (!nearAlertIds.isEmpty()) {
            System.enqueueJob(
                new TokenNearAlertQueueable(nearAlertIds)
            );
        }
    }


    /* AFTER UPDATE
       Recalculate queue
       Check near alert when position changes */
    if (Trigger.isAfter && Trigger.isUpdate) {

        // Recalculate queue when status changes
        TokenQueueRecalculator.recalculateQueue(Trigger.new);

        // Near alert logic
        List<Id> nearAlertIds =
            TokenNearAlertService.getNearAlertTokenIds(
                Trigger.new,
                Trigger.oldMap
            );

        if (!nearAlertIds.isEmpty()) {
            System.enqueueJob(
                new TokenNearAlertQueueable(nearAlertIds)
            );
        }
    }
}