# Event Grid Subscription Creation

# Import data from the CSV file
$csvFile = Import-Csv -Path ".\config.csv"

# Variable definition
$resourceGroupName = "devk8slab01"
$subscriptionId = "c7142d9c-6420-4b6d-a608-d8b19fd4604b"
$topicName = "devk8slabevgr01"
$storageAccountName = "devk8slabsto10"
$ttlInSeconds = 3600

# Iteration through each row of the CSV file
foreach ($row in $csvFile) {

    # Gets the values of the columns ID_queueName and ID_includedEventTypes
    $queueName = $row.ID_queueName
    $includedEventTypes = $row.ID_includedEventTypes

    # Check if the Event Subscription already exists
    $existingSubscription = Get-AzEventGridSubscription -ResourceGroupName $resourceGroupName -EventSubscriptionName $queueName -TopicName $topicName -ErrorAction SilentlyContinue

    if ($existingSubscription -ne $null) {
        Write-Host "Event Subscription '$queueName' already exists for topic '$topicName'. Skipping creation."
    }
    else {
        # Check if the storage queue exists, and if not, create it
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

        if ($storageAccount -eq $null) {
            Write-Host "Storage account '$storageAccountName' does not exist in resource group '$resourceGroupName'. Cannot create the queue."
        }
        else {
            # Verify if the storage queue exists
            $queue = Get-AzStorageQueue -Context $storageAccount.Context -Name $queueName -ErrorAction SilentlyContinue

            if ($queue -eq $null) {
                # The storage queue does not exist, create it
                New-AzStorageQueue -Context $storageAccount.Context -Name $queueName
                Write-Host "Storage Queue '$queueName' created in the storage account."
            }

            # Build the endpoint in the correct format
            $endpoint = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName/queueServices/default/queues/$queueName"

            # Create the subscription in Azure Event Grid with the configured TTL
            New-AzEventGridSubscription `
              -EventSubscriptionName $queueName `
              -ResourceGroupName $resourceGroupName `
              -TopicName $topicName `
              -EndpointType StorageQueue `
              -Endpoint $endpoint `
              -IncludedEventType $includedEventTypes `
              -AdvancedFilteringOnArray `
              -StorageQueueMessageTtl $ttlInSeconds

            Write-Host "Event Subscription '$queueName' created for topic '$topicName'."
        }
    }
}