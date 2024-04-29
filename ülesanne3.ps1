<#
1) Kontrollida et ilne skript töötaks. csv fail täpitähed 
2)Lisa skriptile funktsionaalsus et saab valida kas tehakse juhuslik parool või fikseeritud parool (Parool1).

Selleks et saaks eelmise skripti tulemus faili kasutada on vaja teha natuke eeltööd.
Tehke kindlaks milliseid käsklusi on Powershellis vaja et teha järgnevaid tegevusi.
Tegemist on lokaalse arvutiga ehk teie virtuaalmasinaga. Need käsklused võivad tõenäoliselt vajada administraatori õigusi.

1. Lisada kasutaja lokaalsesse arvutisse täisnime (Eesnimi Perenimi), kasutajanime, parooli ja kirjeldusega.
2. Nõuda kasutajal esmasel sisselogimisel parooli muutmist.
3. Logida arvutisse lisatud kasutaja kontoga.
4. Kustutada kasutajakonto ning kui on kodukaust C:\Users\KASUTAJANIMI, siis ka see ilma lisa küsimusteta.
Kodukaust tekib, kui kontoga on sisse logitud.

Punktid 1, 2 ja 4 peab saama teha Powershell käsklustega, sest neid on hiljem vaja skriptis

Teile on jagatud kolm tekstifaili "Eesnimed", "Kirjeldused", "Perenimed". Failinimi ütleb mida see sisaldab. Teil tuleb luua PS skript,
mis loob juhusliku nime (Eesnimi Perenimi) juhusliku kirjeldusega. Lisaks tuleb genereerida
parool (puhast tekst), mis koosneks ainult tähtedest (SUURED/väiksed) ja numbritest (0-9). Pikkus
5 kuni 8 märki. Lõpuks on vaja juhusliku eesnime ja perekonnanime
põhjal luua kasutajanimi. Kasutajanimi on kujul eesnimi.perenimi. Kui nimi (eesnimi ja/või perenimi)
sisaldab tühikut VÕI sidekriipsu, siis see kirjutatakse kokku. Kasutajanimi on läbivalt
väikestetähtedega. Kogu tulemus kirjutatakse CSV faili. Kui fail on olemas, siis kirjutatakse
failisisu üle! Failinimi on: new_users_accounts.csv Korraga tehakse ainult 5 kasutajat!

CSV faili sisu on järgneval kujul:
Eesnimi;Perenimi;Kasutajanimi;Parool;Kirjeldus

Näiteks:
Eesnimi;Perenimi;Kasutajanimi;Parool;Kirjeldus
Tauno;Korol;tauno.korol;sdf23as;Loob ja arendab tarkvara, tegeleb süsteemi arendusprojektidega.
#>

function Remove-Diacritics {
    param ([String]$src = [String]::Empty)
    $normalized = $src.Normalize([Text.NormalizationForm]::FormD)
    $sb = New-Object Text.StringBuilder
    $normalized.ToCharArray() | ForEach-Object { 
        if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($_)
        }
    }
    $sb.ToString()
  }
  
  # Failide nimed
  $failid = @("Eesnimed.txt", "Perenimed.txt", "Kirjeldused.txt")
  
  # Kontrollime, kas kõik failid on olemas
  foreach ($fail in $failid) {
    if (-not (Test-Path $fail)) {
        Write-Host "$fail puudub"
        return
    }
  }
  
  # Loeme failidest andmed
  $eesnimed = Get-Content -Path "Eesnimed.txt" -Encoding UTF8
  $perenimed = Get-Content -Path "Perenimed.txt" -Encoding UTF8
  $kirjeldused = Get-Content -Path "Kirjeldused.txt" -Encoding UTF8
  
  # Tühjendame faili, kui see on olemas
  if (Test-Path "new_users_accounts.csv") {
    Remove-Item "new_users_accounts.csv"
  }
  
  # Küsime kasutajalt, kas soovitakse kasutada fikseeritud parooli
  $paroolType = Read-Host "Kas soovite kasutada juhuslikku parooli (J) voi fikseeritud parooli (F)?"
  
  # Kui valitakse fikseeritud parool, küsime seda kasutajalt
  if ($paroolType -eq "F") {
    $fixedPassword = Read-Host "Sisestage fikseeritud parool (5-8 märki)"
  }
  
  # Lisame päise
  Add-Content -Path "new_users_accounts.csv" -Value "Eesnimi;Perenimi;Kasutajanimi;Parool;Kirjeldus"
  
  # Loome 5 kasutajat
  for ($i=0; $i -lt 5; $i++) {
    $eesnimi = Get-Random -InputObject $eesnimed
    $perenimi = Get-Random -InputObject $perenimed
    $kirjeldus = Get-Random -InputObject $kirjeldused
  
    # Genereerime parooli vastavalt valikule
    if ($paroolType -eq "J") {
        $parool = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count (Get-Random -Minimum 5 -Maximum 9) | ForEach-Object {[char]$_})
    } elseif ($paroolType -eq "F") {
        $parool = $fixedPassword
    }
  
    # Loome kasutajanime
    $kasutajanimi = Remove-Diacritics(("$eesnimi.$perenimi").ToLower().Replace(' ', '').Replace('-', ''))
  
    # Lisame uue rea CSV faili
    Add-Content -Path "new_users_accounts.csv" -Value "$eesnimi;$perenimi;$kasutajanimi;$parool;$kirjeldus" -Encoding utf8
  }
  Write-Host "Skript jooksis edukalt"
