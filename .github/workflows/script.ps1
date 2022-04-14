Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$installed = Get-InstalledModule -Name Az
if ($installed.Version -eq $null) {
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
}

$path = [Environment]::GetFolderPath("MyDocuments") + "\servers.xml"
$schemaApi = [Environment]::GetFolderPath("MyDocuments") + "\schemaApi.json"

if (Test-Path -Path $path) {
$servers = Import-CliXml -Path $path
$names = $servers.keys | Sort
$names = ,"New APIM" + $names
}
else {
$servers = @{"New APIM" = @{ Name = ''; Emails = ''; Subscriptions = ''; Resources = ''; Services = ''}}
$names = ,"New APIM"
}

function Error-Show {
param ( $ErrorMessage )
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Error Message'
$form.Size = New-Object System.Drawing.Size(500,250)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(400,200)
$label.Text = $ErrorMessage
$form.Controls.Add($label)
$form.Topmost = $true
$result = $form.ShowDialog()
}


$subscription = ''
$resourceGroup = ''
$serviceName = ''
$destResourceGroup = ''
$destServiceName = ''
$destSubscription = ''


function API_picker ($servers, $text){
$form = New-Object System.Windows.Forms.Form
$form.Text = $text
$form.Size = New-Object System.Drawing.Size(700,350)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,250)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(250,250)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Location = New-Object System.Drawing.Point(600,158)
$saveButton.Size = New-Object System.Drawing.Size(75,23)
$saveButton.Text = 'Save'
$saveButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
$form.CancelButton = $saveButton
$form.Controls.Add($saveButton)

$delButton = New-Object System.Windows.Forms.Button
$delButton.Location = New-Object System.Drawing.Point(600,178)
$delButton.Size = New-Object System.Drawing.Size(75,23)
$delButton.Text = 'Remove'
$delButton.DialogResult = [System.Windows.Forms.DialogResult]::No
$form.CancelButton = $delButton
$form.Controls.Add($delButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(400,20)
$label.Text = 'Please enter the required information in the space below:'
$form.Controls.Add($label)

$label0 = New-Object System.Windows.Forms.Label
$label0.Location = New-Object System.Drawing.Point(30,40)
$label0.Size = New-Object System.Drawing.Size(350,20)
$label0.Text = 'Subscription Name (ie. ITP-SharedServicesInternal-npd)'
$form.Controls.Add($label0)

$sub = New-Object System.Windows.Forms.TextBox
$sub.Location = New-Object System.Drawing.Point(30,60)
$sub.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($sub)

$label0 = New-Object System.Windows.Forms.Label
$label0.Location = New-Object System.Drawing.Point(30,90)
$label0.Size = New-Object System.Drawing.Size(350,20)
$label0.Text = 'Email address for above subscription'
$form.Controls.Add($label0)

$acc = New-Object System.Windows.Forms.TextBox
$acc.Location = New-Object System.Drawing.Point(30,110)
$acc.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($acc)

$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(30,140)
$label1.Size = New-Object System.Drawing.Size(280,20)
$label1.Text = 'Resource group (ie. rg-APIManagement-npd)'
$form.Controls.Add($label1)

$rg = New-Object System.Windows.Forms.TextBox
$rg.Location = New-Object System.Drawing.Point(30,160)
$rg.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($rg)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(30,190)
$label2.Size = New-Object System.Drawing.Size(400,20)
$label2.Text = 'Service name (ie. apim-APIMgmtSharedServicesInternal-npd)'
$form.Controls.Add($label2)

$sn = New-Object System.Windows.Forms.TextBox
$sn.Location = New-Object System.Drawing.Point(30,210)
$sn.Size = New-Object System.Drawing.Size(400,20)
$form.Controls.Add($sn)

$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(480,40)
$label3.Size = New-Object System.Drawing.Size(350,20)
$label3.Text = 'Saved managements'
$form.Controls.Add($label3)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(480,60)
$listBox.Size = New-Object System.Drawing.Size(150,20)
$listBox.Height = 80
$listBox.Add_SelectedIndexChanged({ ListIndexChanged })

[void] $listBox.Items.AddRange($names)

$form.Controls.Add($listBox)

$label0 = New-Object System.Windows.Forms.Label
$label0.Location = New-Object System.Drawing.Point(480,140)
$label0.Size = New-Object System.Drawing.Size(350,20)
$label0.Text = 'New name'
$form.Controls.Add($label0)

$new = New-Object System.Windows.Forms.TextBox
$new.Location = New-Object System.Drawing.Point(480,160)
$new.Size = New-Object System.Drawing.Size(100,20)
$form.Controls.Add($new)

$form.Topmost = $true

$form.Add_Shown({$sub.Select()})


function ListIndexChanged { 
    if ($listBox.Text -eq "New APIM") {
            $sub.Text = ''
            $acc.Text = ''
            $rg.Text = ''
            $sn.Text = ''
            $new.Text = ''
            }
    foreach ($server in $servers.keys) {
     if ($server -eq $listBox.Text -and $listBox.Text -ne "New APIM") {
            $sub.Text = $servers.$server.Subscriptions
            $acc.Text = $servers.$server.Emails
            $rg.Text = $servers.$server.Resources
            $sn.Text = $servers.$server.Services
            $new.Text = $servers.$server.Name
            }
            }
}

while (1) {
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $tempAccount = $acc.Text
    $tempResourceGroup = $rg.Text
    $tempServiceName = $sn.Text
    $tempSubscription = $sub.Text
    if ($tempResourceGroup -and $tempServiceName -and $tempSubscription -and $tempAccount) {
    return $tempResourceGroup, $tempServiceName, $tempSubscription, $tempAccount, $servers
    }
} 
if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { exit}
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) { 
    if ($new.Text) {
        $server = @{$new.Text = @{Name = $new.Text; Emails = $acc.Text; Subscriptions = $sub.Text; Resources = $rg.Text; Services = $sn.Text}}
        $servers += $server
        [void] $listBox.Items.Remove($new.Text)
        [void] $listBox.Items.Add($new.Text)
        $servers | Export-CliXml -Path $path
        }
}
if ($result -eq [System.Windows.Forms.DialogResult]::No) { 
    if ($new.Text) {
        $servers.Remove($new.Text)
        [void] $listBox.Items.Remove($new.Text)
        $servers | Export-CliXml -Path $path
        }
        }
}

}

$params = API_picker($servers, 'API from')
$resourceGroup = $params[0]
$serviceName = $params[1]
$subscription = $params[2]
$account = $params[3]
$servers = $params[4]

if ($serviceName -and $resourceGroup -and $subscription -and $account) {
    try{
        $context = Get-AzContext
        if ($context.Account.Id -ne $account) {
            Connect-AzAccount -AccountId $account -Subscription $subscription
        }
        if ($context.SubscriptionName -ne $subscription) {
        Select-AzSubscription -SubscriptionName $subscription
        }
        $context = New-AzApiManagementContext -ResourceGroupName $resourceGroup -ServiceName $serviceName
        $apis = Get-AzApiManagementApi -Context $context -ErrorAction Stop
        }
    catch {
        $_.Exception
        Error-Show -ErrorMessage $_
        break
        }
    }
else { break }

if (-Not $apis) { Error-Show -ErrorMessage "No APIs created" }

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Select an API to copy'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = 'Please select an API:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(260,20)
$listBox.Height = 80

[void] $listBox.Items.AddRange(($apis | Select @{n='Name';e={"{0} {1}" -f $_.Name, $_.ApiVersion}} | Select -Expandproperty name))

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()
if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) { exit}
if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
    foreach ($api in $apis) {
        if ($x -like '*' + $api.Name + '*' -and $x -like '*' + $api.ApiVersion + '*') 
            { 
                $apiID = $api.ApiId 
                $apiName = $api.Name
                $apiVersion = $api.ApiVersion
            }
        }
}

$apiData = Get-AzApiManagementApi -context $context -ApiId $apiID -ErrorAction Stop
$apiVersionSet = Get-AzApiManagementApiVersionSet -Context $context | Where-Object { $_.DisplayName -eq "$apiName" } | Sort-Object -Property ApiVersionSetId -Descending | Select-Object -first 1
$apiOperations = Get-AzApiManagementOperation -context $context -ApiId $apiID -ErrorAction Stop
$apiSchema = Get-AzApiManagementApiSchema -context $context -ApiId $apiID
$apiExport = Export-AzApiManagementApi -context $context -ApiId $apiID -SpecificationFormat OpenApiJson -SaveAs $schemaApi -Force
$policy = @{}
foreach($operation in $apiOperations) {
    $operation
    $policyPath = "$PSScriptRoot\" + $operation.Name
    $policy[$operation.Name] = Get-AzApiManagementPolicy -context $context -ApiId $apiID -OperationId $operation.OperationId -ErrorAction Stop 
    }

$params = API_picker($servers,'API to')
$destResourceGroup = $params[0]
$destServiceName = $params[1]
$destSubscription = $params[2]
$destAccount = $params[3]
$servers = $params[4]


if ($destServiceName -and $destResourceGroup -and $destSubscription) {
    if ($dev) {"before azure subscribtion change"}
    try{
        $context = Get-AzContext
        if ($context.Account.Id -ne $destAccount) {
            Connect-AzAccount -AccountId $destAccount  -Subscription $destSubscription
        }
        if ($context.SubscriptionName -ne $destSubscription) {
        Select-AzSubscription -SubscriptionName $destSubscription
        }
        $context = New-AzApiManagementContext -ResourceGroupName $destResourceGroup -ServiceName $destServiceName
        $apis = Get-AzApiManagementApi -Context $context -ErrorAction Stop
        }
    catch {
        $_.Exception
        Error-Show -ErrorMessage $_
        break
        }
    }
else { break }

$update = 0
foreach ($api in $apis) {
if ($apiID -eq $api.ApiId) { $update = 1 }
}


if ($update -eq 1) {
$form = New-Object System.Windows.Forms.Form
$form.Text = 'API exists'
$form.Size = New-Object System.Drawing.Size(500,150)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,60)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'Yes'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,60)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'No'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(400,20)
$label.Text = 'API ' + $apiID + ' exists. Do you want to overwrite?'
$form.Controls.Add($label)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $update = 1
}
else { break }
}



$destApiVersionSet = Get-AzApiManagementApiVersionSet -Context $context | Where-Object { $_.DisplayName -eq "$apiName" } | Sort-Object -Property ApiVersionSetId -Descending | Select-Object -first 1
if($destApiVersionSet -eq $null -and $apiVersionSet -ne $null)
{
    $versionSet = New-AzApiManagementApiVersionSet -Context $context -Name $apiName -Scheme Segment -Description $apiName
    $versionSetId = $versionSet.Id
}
else
{
    $versionSetId = $destApiVersionSet.ApiVersionSetId
}
$apiData | New-AzApiManagementApi -Context $context -ApiId $apiID -ErrorAction Stop -ApiVersionSetId $versionSetId
Import-AzApiManagementApi -Context $context -ApiId $apiID -SpecificationFormat OpenApiJson -SpecificationPath $schemaApi -Path $apiData.Path -ErrorAction Stop -ApiVersionSetId $versionSetId
Set-AzApiManagementApi -Context $context -ApiId $apiID -Name $apiData.Name -Description $apiData.Description -ServiceUrl $apiData.ServiceUrl -Path $apiData.Path -Protocols $apiData.Protocols -AuthorizationServerId $apiData.AuthorizationServerId -AuthorizationScope $apiData.AuthorizationScope -OpenIdProviderId $apiData.OpenidProviderId -BearerTokenSendingMethod $apiData.BearerTokenSendingMethod -SubscriptionKeyHeaderName $apiData.SubscriptionKeyHeaderName -SubscriptionKeyQueryParamName $apiData.SubscriptionKeyQueryParamName
$destOperations = Get-AzApiManagementOperation -context $context -ApiId $apiID -ErrorAction Stop
foreach($operation in $destOperations) {
    if ($policy[$operation.Name]) {
        Set-AzApiManagementPolicy -context $context -Policy $policy[$operation.Name] -ApiId $apiID -OperationId $operation.OperationId -ErrorAction Stop
        }
    }
remove-item -Path $schemaApi
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Done'
$form.Size = New-Object System.Drawing.Size(250,110)
$form.StartPosition = 'CenterScreen'

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,10)
$label.Size = New-Object System.Drawing.Size(400,200)
$label.Text = "API Copied Successfully"
$form.Controls.Add($label)
$form.Topmost = $true
$result = $form.ShowDialog()
