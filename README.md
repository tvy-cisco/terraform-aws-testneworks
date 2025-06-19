
Right now only Network 4 and Network 5 are supported (IPV6 only). https://confluence-eng-rtp2.cisco.com/conf/display/PROD/Test+Network+Design

# Requirements
- Python 3 installed
- Terraform installed (https://developer.hashicorp.com/terraform/install)
- Streamline installed (https://docs.strln.net/hc/en-us/articles/360025226072-Streamline-CLI-Installing-the-CLI-Manually)
- Streamline permission created for your user (https://docs.strln.net/hc/en-us/articles/360036844571-How-to-get-Streamline-for-your-team)

>[!NOTE] 
>The Streamline command is cumbersome to type, so we will create an alias for it - `onprem-test-eng`
>
>Mac Zshell: Add this alias to your .zshrc so you don't need to remember this
>```
>function sllogin() {
>OUTPUT=$(sl aws session generate --account-id ${ACCOUNT_ID} --role-name ${ROLE})
>URL=$(echo "${OUTPUT}" | grep 'https://signin.aws.amazon.com/')
>if [[ "$URL" == "" ]]; then
>echo "$OUTPUT"
>else
>open "${URL}"
>fi
>}
>
>alias onprem-test-eng='ROLE=engineer ACCOUNT_ID=355747651457 sllogin'
>```
>
>Windows Powershell: Add this alias to your $profile so you don't need to remember the strln command
>```
>Remove-Item Alias:sl -Force
>
>function Sllogin {
>    $AccountId = "355747651457"
>    $RoleName = "engineer"
>    # Run the 'sl aws session generate' command and capture the output
>    $Output = sl aws session generate --account-id $AccountId --role-name $RoleName
>
>    # Find the URL that matches the AWS sign-in pattern
>    $Url = $Output -match 'https://us-east-1.signin.aws.amazon.com/' | Out-String
>
>    if ($Url -eq $null -or $Url -eq "") {
>        # If no URL is found, output the original command's output
>        Write-Output $Output
>    } else {
>        # If a URL is found, open it in the default browser
>        Start-Process $Url
>    }
>}
>
># Define an alias for the specific role and account
>Set-Alias -Name onprem-test-eng -Value Sllogin 
>```


# Test Networks Setup
>[!CAUTION]
>Skip this step if you just want to use the test networks and not create them.
>We may end up with a lot of duplicate resources if multiple people try to setup them up - I still need to figure out how we want to use this 

This will create the test networks 
Run `onprem-test-eng` to login to Streamline and get the AWS credentials for the test networks.
Use `terraform init` to initialize the Terraform configuration.
Use `terraform apply` to create the resources for test networks.
Use `terraform destroy` to remove the resources for the test networks.

# Test Network Usage
Run `onprem-test-eng` to login to Streamline and get the AWS credentials for the test networks.
cd into `python_scripts` directory
Use `terraform init` and `terraform apply` to fetch ips for the test instances for the script to use.
Use `pip install -r ./requirements.txt` to install the required packages.
Use the `python ./network_switch.py {test_network_number}` to configure the test instances and will create ssh tunnels for you for RDP and VNC.
To skip configuring and just create the ssh tunnels, use `python ./network_switch.py {test_network_number} --skip`.
`Ctrl + C` to stop the script and kill the ssh tunnels.

### RDP / VNC into test instances
RDP Windows - localhost:7066
VNC MacOS - localhost:7077

### Manual SSH Tunnels
Run `terraform output` to get the ssh command to create a ssh tunnel to the test instances.
