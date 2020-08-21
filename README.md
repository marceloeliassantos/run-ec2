# BlueHat Tech EC2 instance creation shell script!
This shell script creates EC2 instances and, in addition, during the process performs the following tasks:
* Creates group security with rules
* Create a key pair
* Adds tags on Instance, Group Security and instance volumes
* Read a powershall userdata where it change the hostname and administrator password for Windows 2016 or higher

To choose which region the instance will be created in, run <code> aws configure </code>, and specify the region as shown below:

<pre>aws configure
AWS Access Key ID [****************5JKA]:
AWS Secret Access Key [****************WcJ0]:
Default region name [us-east-1]: us-east-2
Default output format [json]: </pre>

See, that I just hit <code> Enter </code> for the first two options, because I already have my AWS connection set up. And I specified <code> us-east-2 </code> as a new region. If you are not yet connected to AWS, search for the <code> aws configure </code> command to see how to establish a connection with AWS.

### Notes:
* Before running this shell script, open the code and try to understand what it does. Change it as needed.
* The userdata here is for Windows only.
* If an error appears saying that the SubnetId does not exist, it can be for two reasons: 1- It does not really exist. 2- You can be in the different region of the SubnetId that you specified. Which may be the most common mistake.
* When choosing the option to use the password defined in userdata, wait at least 3 minutes before trying to make an RDP connection.
* If the option of random password with key pair is chosen, in addition to displaying a cryptographic key in the terminal, a file will be created with the content of the key in the same directory as this script, in the following format: hostname-keypair.pem

To use this shell script, enter the following commands:
 
<pre>
git clone https://github.com/marceloeliassantos/run-ec2
cd run-ec2
chmod +x run-ec2.sh
./run-ec2.sh
</pre>
See the tutorial video for this script on youtube
[![](https://bluehat.site/images/youtube-screen.png)](https://www.youtube.com/watch?v=-1Qh28pwDNg "Click here to watch.")

Visit my Blog [https://bluehat.site/](https://bluehat.site/)
