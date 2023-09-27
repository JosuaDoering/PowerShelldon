function New-Password {
    <#
        .SYNOPSIS
        Generate a secure password.

        .DESCRIPTION
        Generate a secure password with a single line of code.

        .PARAMETER Length
        Length of the new password (default is 8)

        .PARAMETER ExcludeCharacters
        Define characters that you want to exclude from the pool of possible characters for the generated password.

        .PARAMETER ExcludeSpecialCharacters
        Exclude special characters from the pool of possible characters for the generated password. The following characters are excluded: ~!@#$%^&*_-+=\(){}[]:;<>.?/,

        .PARAMETER ExcludeCharacters
        The space character " " is excluded from the pool of possible characters for the generated password. The space character is very good against brute force attacks, but not all authentications support it.

        .PARAMETER CharacterPool
        Define your own pool of characters for the generated password. The default character pool contains all upper case and lower case letters, numbers and many special characters.

        .EXAMPLE
        # Create a simple password with a length of 12 characters using the default pool of characters. The default pool contains all upper case and lower case letters, numbers and many special characters.
        $newPassword = New-Password -Length 12
        Set-ADAccountPassword -Identity 'serviceuser' -OldPassword (ConvertTo-SecureString -AsPlainText 'OldPassword' -Force) -NewPassword $newPassword

        .EXAMPLE
        # Create a password with the default length of 8 characters excluding the characters ABC<>.
        $pwd = New-Password -ExcludeCharacters 'A', 'B', 'C', '<', '>'

        .EXAMPLE
        # Create a password using only 123456789.
        $pwd = New-Password -CharacterPool '1', '2', '3', '4', '5', '6', '7', '8', '9'

        .EXAMPLE
        # Create a password without special characters and numbers.
        $pwd = New-Password -ExcludeSpecialCharacters -ExcludeCharacters '1', '2', '3', '4', '5', '6', '7', '8', '9'
    #>
    param (
        [int]$Length = 8,
        [string[]]$ExcludeCharacters,
        [switch]$ExcludeSpecialCharacters,
        [switch]$ExcludeSpaceCharacter,
        [string[]]$CharacterPool
    )

    if ($CharacterPool) {
        $size = $CharacterPool.Count / 4
        $items = New-Object System.Collections.Generic.List[object]
        $items.AddRange($CharacterPool)
        $chunkCount = [Math]::Floor($items.Count / $size)
        $CharacterPool = New-Object System.Collections.ArrayList
        foreach ($chunkNdx in 0..($chunkCount - 1)) {
            $null = $CharacterPool.Add($items.GetRange($chunkNdx * $Size, $Size).ToArray())
        }
        if ($chunkCount * $Size -lt $items.Count) {
            $null = $CharacterPool.Add($items.GetRange($chunkCount * $Size, $items.Count - $chunkCount * $Size).ToArray())
        }
    }
    else {
        [System.Collections.ArrayList]$CharacterPool = @(
            @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'),
            @('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'),
            @('1', '2', '3', '4', '5', '6', '7', '8', '9'),
            @('~', '!', '@', '#', '$', '%', '^', '&', '*', '_', '-', '+', '=', '\', '(', ')', '{', '}', '[', ']', ':', ';', '<', '>', ',', '.', '?', '/', ' ')
        )
    }

    $exclusionArray = @()
    $exclusionArray += $ExcludeCharacters
    if ($ExcludeSpecialCharacters) {
        $exclusionArray += '~', '!', '@', '#', '$', '%', '^', '&', '*', '_', '-', '+', '=', '\', '(', ')', '{', '}', '[', ']', ':', ';', '<', '>', ',', '.', '?', '/', ' '
    }
    if ($ExcludeSpaceCharacter) {
        $exclusionArray += ' '
    }

    $PWGeneratorString = New-Object System.Collections.ArrayList
    foreach ($array in $CharacterPool) {
        $array = $array | Where-Object { $PSItem -notin $exclusionArray }
        $null = $PWGeneratorString.Add($array)
    }

    $pwString = @()
    for ($i = 0; $i -lt $Length; $i++) {
        foreach ($array in $PWGeneratorString) {
            $pwString += $array | Get-Random -Count 1
        }
    }

    return (($pwString | Sort-Object { Get-Random }) -join '').Substring(0, $Length)
}