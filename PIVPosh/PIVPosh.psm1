$BaseURI = 'https://network.pivotal.io'
$Uri = $BaseUri + '/api/v2/authentication'
###
function Get-PIVProducts {
    $Uri = $BaseURI + "/api/v2/products"
    $method = "GET"
    $response = Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers -ContentType $ContentType
    ## retain slug´s
    $slugs = ($response.Content | ConvertFrom-Json).products | Select-Object name, slug, id
    Write-Output  $slugs
}
###releases
function Get-PIVRelease {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$id)
    begin {
    }
    process {
        $uri = $BaseURI + "/api/v2/products/$id/releases"
        $method = "GET"
        $response = Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers   -ContentType $ContentType
        $Release = ($response.Content | ConvertFrom-Json).releases | Select-Object -Property @{N="slugid";E={$id}},* # -ExcludeProperty eula,_links,release_notes_url
        Write-Output $release
    }
    end {
    }
}
### GET /api/v2/products/:product_slug/releases/:id
###releases
function Get-PIVFileReleaseId {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$slugid,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$id)
    begin {}
    process {
        $method = 'GET'
        $uri = $BaseURI + "/api/v2/products/$slugid/releases/$id"
        $response = Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers   -ContentType $ContentType
        $releseID = ($response.Content |ConvertFrom-Json).Product_files
        $releseID | Select-Object * -ExpandProperty _links
    }
    end {}
}
## transfer files
## /api/v2/products/:product_slug/releases/:release_id/product_files/:id/download
### releases
function Get-PIVfile {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$slugid,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$id)
    $method = 'GET'
    $uri = $BaseURI + "/api/v2/products/$slugid/releases/$release_id/product_files/$id/download"
    $response = Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers   -ContentType $ContentType
    Write-Output ($response.Content |ConvertFrom-Json).Product_files
}
function Get-PIVFileByUri {
    param(
        $downloaduri = "https://network.pivotal.io/api/v2/products/stemcells/releases/129488/product_files/161630/download",
        $object_key = "product_files/Pivotal-CF/bosh-stemcell-3445.51-azure-hyperv-ubuntu-trusty-go_agent.tgz",
        $access_token
    )
    $headers = @{'Accept' = "application/json"
        'Authorization' = "Bearer $access_token"
        'Content-Length' = 0
        'Content-Type' = "application/json"
        'Host' = "network.pivotal.io"
    }
    $headers
    $file = Split-Path -Leaf $object_key
    Write-Output $file
    $method = 'GET'
    $uri = $downloaduri
    invoke-WebRequest -Method $Method -Uri $URI -Headers $headers   -OutFile "$HOME/Downloads/$file"
}
function Get-PIVFilebyReleaseObject {
    [CmdletBinding(HelpUri = "")]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][array]$releaseobject,
        [Parameter(Mandatory = $true)]$access_token
    )
    begin {
        $headers = @{'Accept' = "application/json"
            'Authorization' = "Bearer $($access_token.access_token)"
            'Content-Length' = 0
            'Content-Type' = "application/json"
            'Host' = "network.pivotal.io"
        }
    }
    process {
        $releaseobject
        pause
        Write-Verbose $headers
        $file = Split-Path -Leaf $releaseobject.aws_object_key
        Write-Host "Downloading $file"
        $method = 'GET'
        $uri = $releaseobject.download.href
        invoke-WebRequest -Method $Method -Uri $URI -Headers $headers   -OutFile "$HOME/Downloads/$file"
    }
    end {}
}
function Get-PIVaccesstoken {
    param(
        # the refres token provided from your Pivotal Net Profile
        [Parameter(Mandatory = $true)]
        [string]
        $refresh_token
    )
    $Method = 'POST'
    $Body = @{'refresh_token' = $refresh_token} | ConvertTo-Json
    $Uri = $BaseUri + "/api/v2/authentication/access_tokens"
    $Headers = @{'Accept' = "text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5"
        'Content-Type' = "application/x-www-form-urlencoded"
    }
    $response = Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers  -Body $Body
    Write-Output $response.Content | ConvertFrom-Json
}
function Confirm-PIVEula {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$slugid,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]$id,
        [Parameter(Mandatory = $true)]$access_token
    )
    begin{}
    process{
    $Method = 'POST'
    $URI = $BaseURI + "/api/v2/products/$slugid/releases/$id/eula_acceptance"
    $headers = @{'Accept' = "application/json"
        'Authorization' = "Bearer $($access_token.access_token)"
        'Content-Length' = 0
        'Content-Type' = "application/json"
        'Host' = "network.pivotal.io"
    }
    Invoke-WebRequest -Method $Method -Uri $URI -Headers $headers
    }
    end{}
}
function Get-PIVSlug {
    [CmdletBinding(HelpUri = "")]
    param (
    )
    DynamicParam {
        $slugs = Get-PIVproducts
        $sluglist = @()
        foreach ($product in $slugs) {
            $sluglist += $product.name
        }
        New-DynamicParam -Name Name -ValidateSet $sluglist -Mandatory
    }
    Begin {
        foreach ($param in $PSBoundParameters.Keys
        ) {
            if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) -and "Verbose", "Debug" -notcontains $param ) {
                New-Variable -Name $Param -Value $PSBoundParameters.$param -Description DynParam
                Write-Verbose "Adding variable for dynamic parameter '$param' with value '$($PSBoundParameters.$param)'"
            }
        }
        $slugs | Where-Object { $_.name -eq $name } | Select-Object id, slug, name
    }
}
function New-DynamicParam {
    param(

        [string]
        $Name,

        [string[]]
        $ValidateSet,

        [switch]
        $Mandatory,

        [string]
        $ParameterSetName = "__AllParameterSets",

        [int]
        $Position,

        [switch]
        $ValueFromPipelineByPropertyName,

        [string]
        $HelpMessage,

        [validatescript( {
                if (-not ( $_ -is [System.Management.Automation.RuntimeDefinedParameterDictionary] -or -not $_) ) {
                    Throw "DPDictionary must be a System.Management.Automation.RuntimeDefinedParameterDictionary object, or not exist"
                }
                $True
            })]
        $DPDictionary = $false

    )
    #Create attribute object, add attributes, add to collection
    $ParamAttr = New-Object System.Management.Automation.ParameterAttribute
    $ParamAttr.ParameterSetName = $ParameterSetName
    if ($mandatory) {
        $ParamAttr.Mandatory = $True
    }
    if ($Position -ne $null) {
        $ParamAttr.Position = $Position
    }
    if ($ValueFromPipelineByPropertyName) {
        $ParamAttr.ValueFromPipelineByPropertyName = $True
    }
    if ($HelpMessage) {
        $ParamAttr.HelpMessage = $HelpMessage
    }

    $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
    $AttributeCollection.Add($ParamAttr)

    #param validation set if specified
    if ($ValidateSet) {
        $ParamOptions = New-Object System.Management.Automation.ValidateSetAttribute -ArgumentList $ValidateSet
        $AttributeCollection.Add($ParamOptions)
    }


    #Create the dynamic parameter
    $Parameter = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList @($Name, [string], $AttributeCollection)

    #Add the dynamic parameter to an existing dynamic parameter dictionary, or create the dictionary and add it
    if ($DPDictionary) {
        $DPDictionary.Add($Name, $Parameter)
    }
    else {
        $Dictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $Dictionary.Add($Name, $Parameter)
        $Dictionary
    }
}