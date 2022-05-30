param(
    [Parameter(Mandatory = $true)]
    [string]$rootPath,

    [Parameter(Mandatory = $true)]
    [int]$maxDays,

    [ValidateSet("true", "false")]
    [string]$deleteCompressedFilesArg = "false",

    [string]$storePath
)

# compress only these services
$services = @('Engine', 'Printing', 'Proxy', 'Repository', 'Scheduler')
# compress only these folders inside each service
$logs = @('Audit', 'System', 'Trace')
$Tab = [char]9

# delete the files after compression
$deleteCompressedFiles = $False

if ($rootPath -eq "") {
    Write-Error "Please provide root path" -ErrorAction:Stop
}

if ($maxDays -lt 1) {
    Write-Error "Max days is not set or its equal to 0 " -ErrorAction:Stop
}

if ($deleteCompressedFilesArg -eq "true") {
    $deleteCompressedFiles = $True
}

# get the current date
$curr_date = Get-Date

# determine how far back we go based on current date
$zip_date = $curr_date.AddDays(-$maxDays)

# compress the files
function archiveLogs ($files, $logPath, $service, $node, $log) {
    # group the files based on their name (extract year and month from the name)
    # SENSE-NODE_AuditActivity_Engine_2021-06-15T06.32.33Z.log
    $groups = $files | 
    Group-Object { $_.BaseName.Substring($_.BaseName.Length - 20, 7) }

    # process each group
    ForEach ($group in $groups) {
        ForEach ($file in $group.Group) {
            $zipName = $node + "_" + $service + "_" + $log + "_" + $group.Name + ".zip"

            if ((Test-Path $logPath) -eq $false) {
                New-Item -ItemType Directory -Path $logPath -Force | Out-Null
            }

            # the actuall compression command
            Compress-Archive -Path $file.FullName -Update -DestinationPath ( $logPath + "\" + $zipName)

            # delete the processed files if specified
            if ($deleteCompressedFiles -eq $True) {
                Remove-Item $file.BaseName
            }
        }
    }    
}

# check if the actual archive folder exists
if ((Test-Path $rootPath) -eq $false) {
    Write-Error "$rootPath do not exists" -ErrorAction:Stop
}

# get all node folders
$nodes = Get-ChildItem $rootPath

# loop through each node 
ForEach ($node in $nodes) {
    # determine where to store the archive files
    # if "storePath" parameter is provided - store them there
    # else store them into the same folder where the logs files are
    $storePathNode = $node
    
    if ($storePath -ne "") {
        $storePathNode = Join-Path -Path $storePath -ChildPath $node.BaseName
    }    

    Write-Output "Processing $($node.BaseName)"

    ForEach ($service in $services) {
        Write-Output "$Tab $service"

        ForEach ($log in $logs) {
            $servicePath = Join-Path -Path $node -ChildPath $service
            $logPath = Join-Path -Path $servicePath -ChildPath $log
            
            # if the log folder exists
            if ((Test-Path $logPath) -eq $true) {                
                # get all files that are modified/created earlier than $zip_date
                $logFiles = Get-ChildItem $logPath | Where-Object { ($_.LastWriteTime -lt $zip_date) -and ($_.psIsContainer -eq $false) }
                
                # if any files at all then start compression
                if ($($logFiles.Count) -gt 0) {
                    Write-Output "$Tab$Tab $log ($($logFiles.Count))"
                    $storePathCombined = Join-Path -Path $storePathNode -ChildPath $service | Join-Path -ChildPath $log
                    archiveLogs $logFiles $storePathCombined $service $node.BaseName $log
                }
            } 
        }
    }
}

#Clear-Host
