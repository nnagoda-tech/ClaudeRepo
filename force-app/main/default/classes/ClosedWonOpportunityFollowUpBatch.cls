// KAN-1: For every Closed Won Opportunity closed in the last 3 months, create a follow-up
// Task assigned to the Opportunity owner, due 3 days from today.
// Run with: Database.executeBatch(new ClosedWonOpportunityFollowUpBatch());
public with sharing class ClosedWonOpportunityFollowUpBatch implements Database.Batchable<SObject> {

    public static final String TASK_SUBJECT = 'Say hello to Company CEO';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date threeMonthsAgo = Date.today().addMonths(-3);
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE IsWon = true
            AND CloseDate >= :threeMonthsAgo
            AND CloseDate <= :Date.today()
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Task> tasks = new List<Task>();
        Date dueDate = Date.today().addDays(3);

        for (Opportunity opp : scope) {
            tasks.add(new Task(
                Subject = TASK_SUBJECT,
                OwnerId = opp.OwnerId,
                WhatId = opp.Id,
                ActivityDate = dueDate
            ));
        }

        if (!tasks.isEmpty()) {
            insert tasks;
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
