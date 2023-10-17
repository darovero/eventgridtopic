
param(
    [string]$resourcegroup,
    [string]$subscriptionid,
    [string]$topicname,
    [string]$storageaccount
)

# Event Grid Subscription Creation

# Import data from the CSV file
$csvFile = Import-Csv -Path ".\config.csv"

# Variable definition
$ttlInSeconds = 3600

# Iteration in each row of CSV file
foreach ($row in $csvFile) {

    # Gets the values of the columns ID_queueName and ID_includedEventTypes
    $queueName = $row.ID_queueName
    $includedEventTypes = $row.ID_includedEventTypes

    # Check if the Event Subscription already exists
    $existingSubscription = Get-AzEventGridSubscription -ResourceGroupName $resourcegroup -EventSubscriptionName $queueName -TopicName $topicName -ErrorAction SilentlyContinue

    if ($existingSubscription -ne $null) {
        Write-Host "Event Subscription '$queueName' already exists for topic '$topicName'. Skipping creation."
    }
    else {
	
        # Check if the storage queue exists and if not, it will be created
        $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccount
        $queue = Get-AzStorageQueue -Context $storageAccount.Context -Name $queueName 2>$null

        if ($queue -eq $null) {
            New-AzStorageQueue -Context $storageAccount.Context -Name $queueName > $null
        }

        # Build the endpoint in the correct format
        $endpoint = "/subscriptions/$subscriptionid/resourceGroups/$resourcegroup/providers/Microsoft.Storage/storageAccounts/$storageaccount/queueServices/default/queues/$queueName"

        # Create the subscription in Azure Event Grid with the TTL configured
        New-AzEventGridSubscription `
          -EventSubscriptionName $queueName `
          -ResourceGroupName $resourcegroup `
          -TopicName $topicname `
          -EndpointType StorageQueue `
          -Endpoint $endpoint `
          -IncludedEventType $includedEventTypes `
          -AdvancedFilteringOnArray `
          -StorageQueueMessageTtl $ttlInSeconds

        Write-Host "Event Subscription '$queueName' created for topic '$topicname'."
    }
}
