import requests

# This script should post to PasteBin PasteBin
# when we commit to git, using Git Hooks.



# Get the contents of the factory_brain script
def get_script_contents():
    with open("/home/logan/programming/minecraft/opencomputers/factory-brain/src/factory_brain.lua","r") as f:
        script_contents = f.read()
        return script_contents


def post_to_pastebin():

    api_dev_key="ryts-cmkSuk0-MFGi94daa4P7Tyd6jIB"
    api_option="paste"
    api_paste_code=get_script_contents()

    data={
        "api_dev_key":api_dev_key,
        "api_option":api_option,
        "api_paste_code":api_paste_code
    }

    r = requests.post(
    url="https://pastebin.com/api/api_post.php",
    data=data
    )
    

    if r.status_code == 200:
        return(r.text)
    else:
        return(f"ERROR: Status_Code ${r.status_code}")
    #print(r.text)
    #print(r.status_code)


print(post_to_pastebin())
