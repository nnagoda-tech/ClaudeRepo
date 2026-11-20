@isTest
private class AccountTriggerTest {

    private static Opportunity buildOpp(Id accountId, String name, String stage, Decimal amount) {
        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = stage,
            Amount = amount,
            CloseDate = Date.today().addDays(30)
        );
    }

    private static Decimal totalFor(Id accountId) {
        return [SELECT Total_Won_Opportunity_Amount__c FROM Account WHERE Id = :accountId].Total_Won_Opportunity_Amount__c;
    }

    @isTest
    static void newAccountGetsZero() {
        Account acct = new Account(Name = 'New Acct');
        insert acct;

        System.assertEquals(0, totalFor(acct.Id), 'New account should have a zero total');
    }

    @isTest
    static void updateSumsOnlyWonOpportunities() {
        Account acct = new Account(Name = 'Acct With Opps');
        insert acct;

        insert new List<Opportunity>{
            buildOpp(acct.Id, 'Won 1', 'Closed Won', 1000),
            buildOpp(acct.Id, 'Won 2', 'Closed Won', 2500),
            buildOpp(acct.Id, 'Lost', 'Closed Lost', 700),
            buildOpp(acct.Id, 'Open', 'Prospecting', 400)
        };

        update acct;

        System.assertEquals(3500, totalFor(acct.Id), 'Only Closed Won amounts should be summed');
    }

    @isTest
    static void totalIsPerAccountInBulk() {
        List<Account> accts = new List<Account>{
            new Account(Name = 'Bulk A'),
            new Account(Name = 'Bulk B'),
            new Account(Name = 'Bulk C')
        };
        insert accts;

        insert new List<Opportunity>{
            buildOpp(accts[0].Id, 'A Won', 'Closed Won', 100),
            buildOpp(accts[0].Id, 'A Won 2', 'Closed Won', 50),
            buildOpp(accts[1].Id, 'B Won', 'Closed Won', 900)
        };

        update accts;

        System.assertEquals(150, totalFor(accts[0].Id));
        System.assertEquals(900, totalFor(accts[1].Id));
        System.assertEquals(0, totalFor(accts[2].Id), 'Account with no won opps should be zero');
    }

    @isTest
    static void totalIsRecalculatedAndOverwritesManualValue() {
        Account acct = new Account(Name = 'Recalc Acct');
        insert acct;
        Opportunity opp = buildOpp(acct.Id, 'Won', 'Closed Won', 1000);
        insert opp;
        update acct;
        System.assertEquals(1000, totalFor(acct.Id));

        opp.Amount = 1800;
        update opp;

        acct.Total_Won_Opportunity_Amount__c = 99999;
        update acct;

        System.assertEquals(1800, totalFor(acct.Id), 'Trigger should recompute and overwrite manual edits');
    }
}
