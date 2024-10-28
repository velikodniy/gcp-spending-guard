const { CloudBillingClient } = require('@google-cloud/billing');

const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT;
const PROJECT_NAME = `projects/${PROJECT_ID}`;
const billing = new CloudBillingClient();

async function isBillingEnabled(projectName) {
    try {
        const [{billingEnabled}] = await billing.getProjectBillingInfo({ name: projectName });
        return billingEnabled;
    } catch (e) {
        console.log('Unable to determine if billing is enabled, assuming it is');
        return true;
    }
}

async function disableBilling(projectName) {
    const [billingInfo] = await billing.updateProjectBillingInfo({
        name: projectName,
        resource: { billingAccountName: '' },
    });
    return `Billing disabled: ${JSON.stringify(billingInfo)}`;
}

async function processBudgetAlert(pubsubEvent) {
    const pubsubData = JSON.parse(
        Buffer.from(pubsubEvent.data, 'base64').toString()
    );

    if (pubsubData.costAmount <= pubsubData.budgetAmount) {
        return `No action. Current cost: ${pubsubData.costAmount})`;
    }

    if (!PROJECT_ID) {
        return 'No project specified';
    }

    const billingEnabled = await isBillingEnabled(PROJECT_NAME);
    if (billingEnabled) {
        return await disableBilling(PROJECT_NAME);
    } else {
        return 'Billing already disabled';
    }
}

exports.processBudgetAlert = processBudgetAlert;
