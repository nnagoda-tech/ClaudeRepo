@isTest
private class OpportunityTriggerHandlerTest {

    private static Opportunity makeOpp(Id acctId, String name, String stage, Decimal amount) {
        return new Opportunity(
            Name = name,
            AccountId = acctId,
            StageName = stage,
            Amount = amount,
            CloseDate = Date.today()
        );
    }

    private static Decimal total(Id acctId) {
        return [SELECT Total_Won_Opportunity_Amount__c FROM Account WHERE Id = :acctId].Total_Won_Opportunity_Amount__c;
    }

    @isTest
    static void closedWonInsertAndStageChangeAddsAmount() {
        Account a = new Account(Name = 'Test Acct');
        insert a;

        Opportunity won = makeOpp(a.Id, 'Won', 'Closed Won', 1000);
        Opportunity open = makeOpp(a.Id, 'Open', 'Prospecting', 500);
        insert new List<Opportunity>{ won, open };
        System.assertEquals(1000, total(a.Id));

        open.StageName = 'Closed Won';
        update open;
        System.assertEquals(1500, total(a.Id));
    }

    @isTest
    static void amountChangeDeleteAndUndeleteRecalculate() {
        Account a = new Account(Name = 'Test Acct');
        insert a;
        Opportunity won = makeOpp(a.Id, 'Won', 'Closed Won', 1000);
        insert won;

        won.Amount = 2500;
        update won;
        System.assertEquals(2500, total(a.Id));

        delete won;
        System.assertEquals(0, total(a.Id));

        undelete won;
        System.assertEquals(2500, total(a.Id));
    }

    @isTest
    static void movingOpportunityBetweenAccountsUpdatesBoth() {
        Account a1 = new Account(Name = 'A1');
        Account a2 = new Account(Name = 'A2');
        insert new List<Account>{ a1, a2 };
        Opportunity won = makeOpp(a1.Id, 'Won', 'Closed Won', 700);
        insert won;

        won.AccountId = a2.Id;
        update won;
        System.assertEquals(0, total(a1.Id));
        System.assertEquals(700, total(a2.Id));
    }
}
