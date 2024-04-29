# Funktsioon logifaili kirjutamiseks
function Write-LogEntry {
    param (
        [string]$logFilePath,
        [string]$entry
    )
    $timestamp = Get-Date -Format "dd.MM.yyyy HH:mm:ss"
    Add-Content -Path $logFilePath -Value "$timestamp;$entry"
}

# Funktsioon, mis loeb kasutajate andmed CSV-failist
function Import-UserAccounts {
    param (
        [string]$csvFilePath
    )
    if (-not (Test-Path $csvFilePath)) {
        Write-Host "Fail $csvFilePath puudub!" -ForegroundColor Red
        return @()
    }
    Import-Csv $csvFilePath -Delimiter ";" | ForEach-Object {
        [PSCustomObject]@{
            Username = $_.Kasutajanimi
            Password = $_.Parool
            DisplayName = "$($_.Eesnimi) $($_.Perenimi)"
            Description = $_.Kirjeldus
        }
    }
}

# Funktsioon uute kasutajate lisamiseks
function Add-NewUserAccounts {
    param (
        [array]$userAccounts
    )
    $userAccounts | ForEach-Object {
        $username = $_.Username
        $password = $_.Password
        $displayName = $_.DisplayName
        $description = $_.Description
        if ($username.Length -gt 20) {
            Write-Host "Kasutajat $username ei lisatud, kuna kasutajanimi on liiga pikk (üle 20 märgi)." -ForegroundColor Yellow
            return
        }
        if ($description.Length -gt 48) {
            $description = $description.Substring(0, 40) + "..."
        }
        $existingUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
        if (-not $existingUser) {
            $password = ConvertTo-SecureString -String $password -AsPlainText -Force
            New-LocalUser -Name $username -FullName $displayName -Password $password -Description $description -PasswordNeverExpires:$true -AccountNeverExpires:$true -UserMayNotChangePassword:$false
            Write-Host "Kasutaja $username lisatud." -ForegroundColor Green
        } else {
            Write-Host "Kasutajat $username ei lisatud, kuna kasutaja on juba olemas." -ForegroundColor Yellow
            Write-LogEntry -logFilePath "accounts_exists.log" -entry "DUPLIKAAT;$displayName;$username;$password;$description"
        }
    }
}

# Funktsioon kasutajakontode kustutamiseks
function Remove-UserAccount {
    param (
        [int]$selection
    )
    $users = Get-LocalUser | Where-Object { $_.Name -like '*.*' }
    if ($selection -gt 0 -and $selection -le $users.Count) {
        $user = $users[$selection - 1]
        $username = $user.Name
        Remove-LocalUser -Name $username -Confirm:$false
        Write-Host "Kasutaja $username kustutatud." -ForegroundColor Green
        $userProfilePath = Join-Path -Path "C:\Users" -ChildPath $username
        if (Test-Path $userProfilePath) {
            Remove-Item -Path $userProfilePath -Recurse -Force
            Write-Host "Kasutaja kodukaust $username kustutatud." -ForegroundColor Green
        }
    } else {
        Write-Host "Valitud numbriga kasutajat ei leitud." -ForegroundColor Red
    }
}

# Funktsioon, mis loetleb võimalikud kustutatavad kontodfunction Get-DeletableAccounts {
function Get-DeletableAccounts {
    Write-Host "Kõik kasutajakontod, mille kasutajanimedes on punkt:"
    $users = Get-LocalUser | Where-Object { $_.Name -like '*.*' }
    if ($users.Count -eq 0) {
        Write-Host "Punktiga kasutajakontosid ei leitud."
    } else {
        $i = 1
        foreach ($user in $users) {
            Write-Host "$i. Kasutaja $($user.Name) - $($user.FullName)"
            $i++
        }
    }
}

# Küsime kasutajalt, millist tegevust soovitakse teha
$action = Read-Host "Kas soovite lisada (L), kustutada (K)?"

# Käivitame vastava tegevuse sõltuvalt valikust
if ($action -eq "L") {
    $csvFilePath = "new_users_accounts.csv"
    $userAccounts = Import-UserAccounts -csvFilePath $csvFilePath
    if ($userAccounts.Count -gt 0) {
        Add-NewUserAccounts -userAccounts $userAccounts
    } else {
        Write-Host "CSV-failist ei õnnestunud kasutajate andmeid lugeda." -ForegroundColor Red
    }
} elseif ($action -eq "K") {
    # Näitame kasutajale võimalikke kustutatavaid kontosid
    Get-DeletableAccounts
    # Küsime kasutajalt, millist kontot soovitakse kustutada
    $selection = Read-Host "Sisestage kasutajakonto number, mida soovite kustutada"
    Remove-UserAccount -selection $selection
} else {
    Write-Host "Tundmatu valik! Valige kas L (lisamine) või K (kustutamine)" -ForegroundColor Red
}
