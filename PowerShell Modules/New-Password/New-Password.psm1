function New-Password {
    <#
        .SYNOPSIS
        Generate a secure password. 

        .DESCRIPTION
        Generate a secure password with a single line of code. 

        .PARAMETER Length
        Length of the new password

        .EXAMPLE
        $newPassword = New-Password -Length 12
        Set-ADAccountPassword -Identity 'serviceuser' -OldPassword (ConvertTo-SecureString -AsPlainText 'OldPassword' -Force) -NewPassword $newPassword
    #>
    param (
        [int]$Length = 8
    )
    $PWGeneratorString = @(
        @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'),
        @('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'),
        @('1', '2', '3', '4', '5', '6', '7', '8', '9'),
        @('~', '!', '@', '#', '$', '%', '^', '&', '*', '_', '-', '+', '=', '\', '(', ')', '{', '}', '[', ']', ':', ';', '<', '>', ',', '.', '?', '/')
    )


    $pwString = @()
    for ($i = 0; $i -lt [Math]::Ceiling(($Length / $PwGeneratorString.Count)); $i++) {
        foreach ($array in $PWGeneratorString) {
            $pwString += $array | Get-Random -Count 1
        }
    }

    return (($pwString | Sort-Object { Get-Random }) -join '').Substring(0, $Length)
}