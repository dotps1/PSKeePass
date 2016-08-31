Function Get-KeePassEntry {
    
    [CmdletBinding()]
    [OutputType()]

    Param(
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Password"
        )]
        [PSCredential]
        $Credential,

        [Parameter(
            ParameterSetName = "Integrated"
        )]
        [Bool]
        $IntegratedSecurity = $true,
        
        [Parameter(
            Mandatory = $true
        )]
        [ValidateScript({
            if (Test-Path -Path $_) {
                return $true
            } else {
                throw "Invalid path: $_."
            }
        })]
        [Alias(
            "Database"
        )]
        [String]
        $Path,

        [Parameter()]
        [ValidateScript({
            if (Test-Path -Path $_) {
                return $true
            } else {
                throw "Invalid path: $_."
            }
        })]
        [String]
        $KeyFile,

        [Parameter()]
        [String]
        $Title = "*"
    )

    Begin {
        $compositeKey = New-Object -TypeName KeePassLib.Keys.CompositeKey

        switch ($PSCmdlet.ParameterSetName) {
            "Password" {
                $compositeKey.AddUserKey(
                    [KeePassLib.Keys.KcpPassword]::new(
                        $Credential.GetNetworkCredential().Password
                    )
                )
                
                if ($PSBoundParameters.ContainsKey("KeyFile")) {
                    $compositeKey.AddUserKey(
                        [KeePassLib.Keys.KcpKeyFile]::new(
                            $KeyFile
                        )
                    )
                }
            }

            "Integrated" {
                $compositeKey.AddUserKey(
                    [KeePassLib.Keys.KcpUserName]::new()
                )
            }
        }

        $ioConnectionInfo = New-Object -TypeName KeePassLib.Serialization.IOConnectionInfo -Property @{
            Path = "$Path"
        }

        try {
            $pwDatabase = New-Object -TypeName KeePassLib.PwDatabase
            $pwDatabase.Open(
                $ioConnectionInfo, $compositeKey, [KeePassLib.Interfaces.NullStatusLogger]::new()
            )
        } catch {
            throw $_
        }

        $items = $pwDatabase.RootGroup.GetObjects($true, $true)
    }

    Process {
        foreach ($item in $items.Where({ $_.Strings.ReadSafe("Title") -like $Title })) {
            [HashTable]@{
                Title = $item.Strings.ReadSafe("Title")
                UserName = $item.Strings.ReadSafe("UserName")
                Password = $item.Strings.ReadSafe("Password")
                URL = $item.Strings.ReadSafe("URL")
                Notes = $item.Strings.ReadSafe("Notes")
            }
        }
    }

    End {
        $pwDatabase.Close()
    }
}
