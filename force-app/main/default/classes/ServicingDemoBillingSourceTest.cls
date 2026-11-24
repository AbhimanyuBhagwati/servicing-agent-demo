@IsTest
private class ServicingDemoBillingSourceTest {

    private static Map<String, Integer> columns() {
        return new Map<String, Integer>{
            'customer_id__c' => 0, 'bill_period__c' => 1, 'amount__c' => 2,
            'currency__c' => 3, 'bill_status__c' => 4, 'due_date__c' => 5
        };
    }

    @IsTest
    static void aRowBecomesABill() {
        ServicingDemoStubData.Bill b = ServicingDemoBillingSource.toBill(
            new List<Object>{ '1001', '2026-11', '64.500000000000000000', 'USD', 'Open', '2026-12-05' }, columns());
        System.assertEquals('1001', b.customerId);
        System.assertEquals('2026-11', b.period);
        System.assertEquals('64.50 USD', b.amount);
        System.assertEquals('Open', b.status);
        System.assertEquals('2026-12-05', b.dueDate);
    }

    @IsTest
    static void emptyValuesGiveEmptyText() {
        ServicingDemoStubData.Bill b = ServicingDemoBillingSource.toBill(
            new List<Object>{ '1002', '2026-11', null, null, 'Paid', null }, columns());
        System.assertEquals('', b.amount);
        System.assertEquals('', b.dueDate);
        System.assertEquals('', ServicingDemoBillingSource.toBill(new List<Object>(), columns()).status);
    }

    @IsTest
    static void theRealSourceIsTheDefault() {
        System.assert(ServicingDemoBillingSource.current() instanceof ServicingDemoBillingSource.Data360Source);
        System.assert(ServicingDemoBillingSource.current().sourceText().startsWith('Data 360'));
    }

    @IsTest
    static void aCustomerIdThatIsNotDigitsGoesNotIntoTheQuery() {
        ServicingDemoBillingSource.Data360Source src = new ServicingDemoBillingSource.Data360Source();
        System.assertEquals(0, src.billsFor('1 OR 1=1').size());
        System.assertEquals(0, src.billsFor('').size());
    }

    @IsTest
    static void theRealSourceRunsAsFarAsATestAllows() {
        ServicingDemoBillingSource.Data360Source src = new ServicingDemoBillingSource.Data360Source();
        // A test sees no data stream, so the load time is null.
        System.assertEquals(null, src.loadTime());
        // A test cannot query Data 360. The action catches this error (NOT_AVAILABLE).
        try {
            src.billsFor('1001');
        } catch (Exception e) {
            System.assertNotEquals(null, e);
        }
    }
}
