$groupName = ''
$adServer = '' # For Global Catalog

$members = (Get-ADGroup -Identity $groupName -Properties Members).Members

$users = @()
$groups = @()
$groupsDone = @()
$i = 0
foreach ($member in $members) {
    $adObject = Get-ADObject $member -Server "$($adServer):3268"

    if ($adObject.ObjectClass -eq 'group') {
        [string[]]$groups += $adObject.DistinguishedName
    }
    elseif ($adObject.ObjectClass -eq 'user') {
        [string[]]$users += $adObject.DistinguishedName
    }

    foreach ($group in $groups) {
        if ($group -ne '' -and $null -ne $group -and $group -notin $groupsDone) {
            Write-Host "$i $group" -BackgroundColor DarkMagenta
            $adObjects = (Get-ADGroup -Identity $group -Server "$($adServer):3268" -Properties Members).Members

            if ($adObjects) {
                foreach ($adObject in $adObjects) {
                    $adObject = Get-ADObject $adObject -Server "$($adServer):3268"

                    if ($adObject.ObjectClass -eq 'group') {
                        [string[]]$groups += $adObject.DistinguishedName
                    }
                    elseif ($adObject.ObjectClass -eq 'user') {
                        [string[]]$users += $adObject.DistinguishedName
                    }
                }
            }
            $groupsDone += $group
            $groups = $groups | Where-Object { $PSItem -ne $group -and $PSItem -ne '' -and $null -ne $PSItem } | Select-Object -Unique
        }
        $i++
    }
}

$users = $users | Select-Object -Unique
$adUsers = @()
foreach ( $user in $users) {
    $adUsers += Get-ADUser $user -Server "$($adServer):3268"
}

Write-Output $adUsers