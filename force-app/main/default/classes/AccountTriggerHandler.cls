public with sharing class AccountTriggerHandler 
{

      public static void CreateAccounts(List<Account> accounts) {
        for(Account acct : accounts) {
            if(acct.ShippingState == null || ( acct.BillingState != null && acct.ShippingState.compareTo(acct.BillingState) != 0)) {
                acct.ShippingState = acct.BillingState;
            }
        }
    }

    // Sets Total_Won_Opportunity_Amount__c to the sum of Closed Won Opportunity amounts.
    // Intended for before insert / before update, so no extra DML is needed.
    public static void calculateTotalWonOpportunityAmount(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acct : accounts) {
            if (acct.Id != null) {
                accountIds.add(acct.Id);
            }
        }

        Map<Id, Decimal> totals = new Map<Id, Decimal>();
        if (!accountIds.isEmpty()) {
            for (AggregateResult ar : [
                SELECT AccountId acctId, SUM(Amount) total
                FROM Opportunity
                WHERE AccountId IN :accountIds AND IsWon = true
                GROUP BY AccountId
            ]) {
                totals.put((Id) ar.get('acctId'), (Decimal) ar.get('total'));
            }
        }

        for (Account acct : accounts) {
            Decimal total = acct.Id == null ? null : totals.get(acct.Id);
            acct.Total_Won_Opportunity_Amount__c = total == null ? 0 : total;
        }
    }
}