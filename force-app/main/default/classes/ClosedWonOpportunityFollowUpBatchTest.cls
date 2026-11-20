@isTest
private class ClosedWonOpportunityFollowUpBatchTest {

    private static Opportunity makeOpp(Id acctId, String name, String stage, Date closeDate) {
        return new Opportunity(
            Name = name,
            AccountId = acctId,
            StageName = stage,
            Amount = 100,
            CloseDate = closeDate
        );
    }

    // Note: the org has a validation rule requiring CloseDate >= today for Closed Won/Lost
    // opportunities (on insert and update), so a Closed Won opportunity older than 3 months
    // cannot be created in a test. The lower date bound is therefore not covered here.
    @isTest
    static void createsTasksOnlyForClosedWonOpportunitiesInWindow() {
        Account a = new Account(Name = 'Batch Acct');
        insert a;

        Opportunity wonToday = makeOpp(a.Id, 'Won Today', 'Closed Won', Date.today());
        Opportunity wonFuture = makeOpp(a.Id, 'Won Future', 'Closed Won', Date.today().addDays(10));
        Opportunity lost = makeOpp(a.Id, 'Lost', 'Closed Lost', Date.today());
        Opportunity open = makeOpp(a.Id, 'Open', 'Prospecting', Date.today().addDays(10));
        insert new List<Opportunity>{ wonToday, wonFuture, lost, open };

        Test.startTest();
        Database.executeBatch(new ClosedWonOpportunityFollowUpBatch());
        Test.stopTest();

        List<Task> tasks = [
            SELECT Subject, OwnerId, WhatId, ActivityDate
            FROM Task
            WHERE Subject = :ClosedWonOpportunityFollowUpBatch.TASK_SUBJECT
        ];
        System.assertEquals(1, tasks.size(), 'Only the Closed Won opportunity within the window should get a task');
        System.assertEquals(wonToday.Id, tasks[0].WhatId);
        System.assertEquals(UserInfo.getUserId(), tasks[0].OwnerId, 'Task should be assigned to the opportunity owner');
        System.assertEquals(Date.today().addDays(3), tasks[0].ActivityDate, 'Due date should be 3 days from today');
    }
}
