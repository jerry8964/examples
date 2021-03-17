try
{
    # Load WinSCP .NET assembly
    Add-Type -Path "WinSCPnet.dll"

    # Setup session options
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Sftp
        HostName = "example.com"
        UserName = "user"
        Password = "mypassword"
        SshHostKeyFingerprint = "ssh-rsa 2048 xxxxxxxxxxx...="
    }

    $session = New-Object WinSCP.Session

    try
    {
        # Connect
        $session.Open($sessionOptions)

        # Upload files with wildcard
        $transferOptions = New-Object WinSCP.TransferOptions
        $transferOptions.TransferMode = [WinSCP.TransferMode]::Binary

        $targetFiles = "c:\temp\sftp\wildcard*.csv"
        $remotePath = "/home/user/recv"

        $transferResult = $session.PutFiles($targetFiles, $remotePath, $False, $transferOptions)

        # Throw on any error
        $transferResult.Check()

        # Print results
        foreach ($transfer in $transferResult.Transfers)
        {
            Write-Host "Upload of $($transfer.FileName) succeeded"
        }

        # Upload files in a list
        $lines = Get-Content "list.txt"
        foreach ($line in $lines)
        {
            Write-Host "Upload $line ..."
            $session.PutFiles($line, $remotePath).Check()
        }


        # Download files when done file is exist
        $localPath = "C:\temp\sftp"

        $files = $session.EnumerateRemoteFiles($remotePath, "*.done", [WinSCP.EnumerationOptions]::None)
        foreach ($fileInfo in $files)
        {
            # Resolve actual file name by removing the .done extension
            $remoteFilePath = $fileInfo.FullName -replace ".done$", ""
            Write-Host "Downloading $remoteFilePath ..."
            # Download and delete
            $session.GetFiles([WinSCP.RemotePath]::EscapeFileMask($remoteFilePath), $localPath + "\*", $True).Check()
            # Delete ".done" file
            $session.RemoveFiles([WinSCP.RemotePath]::EscapeFileMask($fileInfo.FullName)).Check()
        }
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }

    exit 0
}
catch
{
    Write-Host "Error: $($_.Exception.Message)"
    exit 1
}