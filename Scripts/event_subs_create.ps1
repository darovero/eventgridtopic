param(
    [string]$resourcegroupname,
    [string]$subscriptionId,
    [string]$topicname,
    [string]$storageAccountname
)




# Event Grid Subscription Creation

# Import data from the CSV file
$csvFile = Import-Csv -Path ".\config.csv"

# Variable definition
$ttlInSeconds = 3600

# Iteration through each row of the CSV file
foreach ($row in $csvFile) {

    # Gets the values of the columns ID_queueName and ID_includedEventTypes
    $queueName = $row.ID_queueName
    $includedEventTypes = $row.ID_includedEventTypes

    # Check if the Event Subscription already exists
    $existingSubscription = Get-AzEventGridSubscription -ResourceGroupName $resourcegroupname -EventSubscriptionName $queueName -TopicName $topicname -ErrorAction SilentlyContinue

    if ($null -ne $existingSubscription) {
        Write-Host "Event Subscription '$queueName' already exists for topic '$topicname'. Skipping creation."
    }
    else {
        # Check if the storage queue exists, and if not, create it
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourcegroupname -Name $storageaccountname

        if ($null -eq $storageAccount) {
            Write-Host "Storage account '$storageaccountname' does not exist in resource group '$resourcegroupname'. Cannot create the queue."
        }
        else {
            # Verify if the storage queue exists
            $queue = Get-AzStorageQueue -Context $storageAccount.Context -Name $queueName -ErrorAction SilentlyContinue

            if ($null -eq $queue) {
                # The storage queue does not exist, create it
                New-AzStorageQueue -Context $storageAccount.Context -Name $queueName
                Write-Host "Storage Queue '$queueName' created in the storage account."
            }

            # Build the endpoint in the correct format
            $endpoint = "/subscriptions/$subscriptionid/resourceGroups/$resourcegroupname/providers/Microsoft.Storage/storageAccounts/$storageaccountname/queueServices/default/queues/$queueName"

            # Create the subscription in Azure Event Grid with the configured TTL
            New-AzEventGridSubscription `
              -EventSubscriptionName $queueName `
              -ResourceGroupName $resourcegroupname `
              -TopicName $topicname `
              -EndpointType StorageQueue `
              -Endpoint $endpoint `
              -IncludedEventType $includedEventTypes `
              -AdvancedFilteringOnArray `
              -StorageQueueMessageTtl $ttlInSeconds

            Write-Host "Event Subscription '$queueName' created for topic '$topicname'."
        }
    }
}