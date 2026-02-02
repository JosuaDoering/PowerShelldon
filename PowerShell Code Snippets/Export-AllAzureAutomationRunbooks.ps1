Connect-AzAccount

$runbooks = Get-AzAutomationRunbook -ResourceGroupName 'rg_azure_automation' -AutomationAccountName 'automationaccount'

foreach ($runbook in $runbooks) 
{
    Export-AzAutomationRunbook -ResourceGroupName 'rg_azure_automation' -AutomationAccountName 'automationaccount' -Name $runbook.Name -OutputFolder '/Users/user/Desktop/runbooks'
}

Disconnect-AzAccount