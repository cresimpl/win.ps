param (
    [Parameter(            
        Position = 0,            
        ParameterSetName = 'Nazwa',            
        Mandatory = $true,            
        HelpMessage = 'Składowa nazwy maszyny wirtualnej'
    )]           
    [string] $VmName,

    [Parameter(         
        HelpMessage = 'Ilość kart sieciowych w routerze'
    )]           
    [int] $RTNet = 2,

    [Parameter(         
        HelpMessage = 'Ustawienie vlanu na interfejsie karty sieciowej'
    )]           
    [int] $VLAN = 100,
    
    [Parameter(         
        HelpMessage = 'Blokada ustawienia vlanu na interfejsie karty sieciowej'
    )]           
    [switch] $NOVLAN,
    
    [Parameter(         
        HelpMessage = 'Ilość węzłów'
    )]           
    [int] $Nodes = 1,

    [Parameter(         
    HelpMessage = 'Tworzenie Routera'
    )]           
    [switch] $NORouter

)

#######################################################
##### Szymon Rózański      email: sz.rozanski@gmail.com
#####
##### Program do szybkiego tworzenia środowiska hyper-v
#####
##### ver. 0.1   2015-01-27
#####
#######################################################

## Zmienne programu
#

$VmDir = "V:\vhd-diff\"
$VHDExt = ".vhdx"
$VmPrefix = "${VmName}"
$VmFile = "-diff-fe-21-S64_v1u"
$VmPath = "${VmDir}${VmPrefix}${VmFile}${VHDExt}"
$VmRTPath = "${VmDir}${VmName}_rt${VmFile}${VHDExt}"
$VmParentPath  = "V:\vhd-clean\clean-fe-21-S64_v1u.vhdx"
$WANSwitch = "vswitch"
$LANSwitch = "vswitch${VmName}"
$WAN = "wan"
$LAN = "lan"


## Funkcje
#

# Tworzenie switcha w hyper-v
function Nowy-Switch
{
param([string] $id)
echo "SWITCH $LANSwitch$id"

New-VMSwitch -Name "$LANSwitch$id" -SwitchType Private -Notes "Sieć do projektu $VmName"

}

# Tworzenie maszyny wirtualnej - Router
function Nowy-RT
{
#    param([typ] $nazwa_parametru1, [typ] $nazwa_parametru2 = wartość domyślna)

Write-Host "Tworzenie maszyny wirtualnej - Router" -ForegroundColor Green

New-VHD -ParentPath $VmParentPath -Path $VmRTPath
New-VM -Name ${VmName}_rt -MemoryStartupBytes 1GB -VHDPath $VmRTPath -SwitchName $WANSwitch

Get-VMNetworkAdapter ${VmName}_rt | rename-VMNetworkAdapter -NewName $WAN
Set-VMNetworkAdapter -VMName ${VmName}_rt -Name $WAN -MacAddressSpoofing On

if ($VLAN -ne $null -and $NORouter -eq $false) {Set-VMNetworkAdapterVlan -VMName ${VmName}_rt -VMNetworkAdapterName $WAN -Access -VlanId $VLAN}


if ($RTNet -gt 1) {
    for($i=1; $i -lt $RTNet; $i++) {
    
    Nowy-Switch $($i-1)

    Write-Host "? Ustawienia dla $LANSwitch$($i-1)" -ForegroundColor Green

    Add-VMNetworkAdapter -VMName ${VmName}_rt -Name $LAN$($RTNet-$i) -SwitchName $LANSwitch$($i-1)
    Set-VMNetworkAdapter -VMName ${VmName}_rt -Name $LAN$($RTNet-$i) -MacAddressSpoofing On
    
    }

}

}

# Tworzenie maszyny wirtualnej - Node
function Nowy-Wezel
{
param( [Parameter(Position = 0)] [int] $id, [Parameter(Position = 1)] [int] $SwitchID = 0)

Write-Host "Tworzenie maszyny wirtualnej - Node" -ForegroundColor Green

if ($NORouter -eq $true) {$SwitchName = "$WANSwitch"}
else {$SwitchName = "${LANSwitch}${SwitchID}"}

echo SwitchName = $SwitchName

New-VHD -ParentPath $VmParentPath -Path ${VmDir}${VmPrefix}${id}${VmFile}${VHDExt}
New-VM -Name $VmName$id -MemoryStartupBytes 1GB -VHDPath ${VmDir}${VmPrefix}${id}${VmFile}${VHDExt} -SwitchName $SwitchName

Get-VMNetworkAdapter $VmName$id | rename-VMNetworkAdapter -NewName $LAN
Set-VMNetworkAdapter -VMName $VmName$id -Name $LAN -MacAddressSpoofing On

if ($VLAN -ne $null -and $NORouter -eq $true) {Set-VMNetworkAdapterVlan -VMName ${VmName}$id -VMNetworkAdapterName $LAN -Access -VlanId $VLAN}

}


## Program
#

if ($NORouter -eq $false) {
    Nowy-RT
}

if ($Nodes -gt 0) {
    for($i=1; $i -le $Nodes; $i++) {
    Nowy-Wezel $i 0
}

}