function New-Credential {
    <#
        .SYNOPSIS
        Create a PSCredential object with one simple line of code. 

        .DESCRIPTION
        Create a PSCredential object with one simple line of code instead of two ;)

        .PARAMETER Username
        Username of the PSCredential object

        .PARAMETER Password
        Password of the PSCredential object. This should not be saved in the script as plain text. 

        .EXAMPLE
        $ADCredentials = New-Credential -Username 'serviceuser' -Password 'securepassword'
        Set-ADUser -Identity 'exampleuser' -Department 'HR' -Credentials $ADCredentials
    #>
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Username, 
        [Parameter(Mandatory = $true)]
        [string]$Password
    )

    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force 

    return New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
}