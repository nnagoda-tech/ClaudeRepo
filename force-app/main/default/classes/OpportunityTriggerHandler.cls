public with sharing class OpportunityTriggerHandler {

    // Recalculates Account.Total_Won_Opportunity_Amount__c for every Account affected by
    // Closed Won opportunities being created, changed (stage/amount/account), deleted or undeleted.
    // Recomputing the sum (rather than adding a delta) keeps the total correct on edits and deletes.
    //deployed using MCP
    public static void updateAccountTotalWon(
        List<Opportunity> newList,
        Map<Id, Opportunity> oldMap,
        Boolean isDelete
    ) {
        List<Opportunity> records = isDelete ? oldMap.values() : newList;
        Set<Id> accountIds = new Set<Id>();

        for (Opportunity opp : records) {
            Opportunity oldOpp = (oldMap != null && !isDelete) ? oldMap.get(opp.Id) : null;

            if (oldOpp == null) {
                // insert, undelete, or delete
                if (opp.IsWon && opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
            } else if (
                opp.IsWon != oldOpp.IsWon ||
                opp.Amount != oldOpp.Amount ||
                opp.AccountId != oldOpp.AccountId
            ) {
                // update that could change a total (old and new account both need recalculating)
                if (opp.AccountId != null) {
                    accountIds.add(opp.AccountId);
                }
                if (oldOpp.AccountId != null) {
                    accountIds.add(oldOpp.AccountId);
                }
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        for (AggregateResult ar : [
            SELECT AccountId acctId, SUM(Amount) total
            FROM Opportunity
            WHERE AccountId IN :accountIds AND IsWon = true
            GROUP BY AccountId
        ]) {
            totals.put((Id) ar.get('acctId'), (Decimal) ar.get('total'));
        }

        List<Account> toUpdate = new List<Account>();
        for (Id acctId : accountIds) {
            Decimal total = totals.get(acctId);
            toUpdate.add(new Account(
                Id = acctId,
                Total_Won_Opportunity_Amount__c = total == null ? 0 : total
            ));
        }
        update toUpdate;
    }
}
