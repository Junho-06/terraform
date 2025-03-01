import json
import sys
import requests

region = sys.argv[1]
os_name = sys.argv[2]
architecture = sys.argv[3]

url = f"https://prod.{region}.qs.console.ec2.aws.dev/get_quickstart_list_ko.json"
response = requests.get(url)
response.raise_for_status()
data = response.json()

ami_list = data.get("amiList", [])
matched_amis = []

for item in ami_list:
    if os_name in item.get("title", ""):
        if "Amazon Linux 2 AMI" in os_name or "Ubuntu" in os_name:
            if architecture == "x86_64" and "imageId64" in item:
                matched_amis.append(item["imageId64"])
            elif architecture == "arm64" and "imageIdArm64" in item:
                matched_amis.append(item["imageIdArm64"])
        else:
            for arch in item.get("architectures", []):
                if arch.get("architectureType") == architecture:
                    matched_amis.append(arch.get("imageId"))

if matched_amis:
    print(json.dumps({"ami_id": matched_amis[0]}))
    sys.exit(0)

print(json.dumps({"error": f"AMI not found for OS: {os_name}, Arch: {architecture}"}))
sys.exit(1)