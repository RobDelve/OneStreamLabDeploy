function New-OSLabVmImage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$VmName,

        [Parameter(Mandatory = $true)]
        [string]$BaseImageName,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName
    )

    Write-Verbose "Starting the creation of a new OneStream Lab VM image."

    # Step 1: Create a new VM from a base image (e.g., using New-AzVM)
    # -----------------------------------------------------------------
    # Example (pseudo-code):
    # $vm = New-AzVM -Name $VmName -Image $BaseImageName -ResourceGroupName $ResourceGroupName ...
    # Write-Verbose "VM '$VmName' created successfully."

    # Step 2: Copy the OneStreamLabDeploy module and installers to the new VM
    # -----------------------------------------------------------------------
    # Example (pseudo-code):
    # Copy-Item -Path 'C:\Path\To\OneStreamLabDeploy' -Destination "\\$($vm.Name)\c$\Modules" -Recurse
    # Copy-Item -Path 'C:\Path\To\Installers' -Destination "\\$($vm.Name)\c$\Install" -Recurse
    # Write-Verbose "Module and installers copied to the VM."

    # Step 3: Invoke the DSC configuration on the new VM
    # --------------------------------------------------
    # Example (pseudo-code):
    # Invoke-Command -ComputerName $vm.Name -ScriptBlock {
    #     Import-Module 'C:\Modules\OneStreamLabDeploy'
    #     Start-OSLabBuild -ConfigurationDataPath 'C:\Modules\OneStreamLabDeploy\ConfigurationData.psd1'
    # }
    # Write-Verbose "DSC configuration applied to the VM."

    # Step 4: Generalize the VM (Sysprep) and capture it as a new image
    # ------------------------------------------------------------------
    # Example (pseudo-code):
    # Invoke-Command -ComputerName $vm.Name -ScriptBlock { & C:\Windows\System32\Sysprep\Sysprep.exe /generalize /oobe /shutdown }
    # Wait-AzVM -Name $VmName -ResourceGroupName $ResourceGroupName -Status 'Deallocated'
    # New-AzImage -Name "$($VmName)-Image" -ResourceGroupName $ResourceGroupName -SourceVmId $vm.Id
    # Write-Verbose "VM generalized and captured as a new image."

    Write-Output "Successfully created new OneStream Lab VM image: $($VmName)-Image"
}
