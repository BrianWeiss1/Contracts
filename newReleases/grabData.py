# import dextools
# import requests
# dextoolsAPI = dextools.DextoolsAPIV2('xf2sLeG1qiFRN59OvUo2tKkUCrtHSbkT')
# dextoolsAPI.get_token('bnb', '0x88da9901b3a02fe24e498e1ed683d2310383e295')
# chain='bnb'
# address = '0x88da9901b3a02fe24e498e1ed683d2310383e295'

# url = f"https://ope-n-api.dextools.io/free/v2/token/{chain}/{address}"

# headers = {
#   "X-BLOBR-KEY": "xf2sLeG1qiFRN59OvUo2tKkUCrtHSbkT"
# }


# # params = {
  
# # }

# response = requests.get(url, headers=headers)

# print(response.text)

import requests

url = "https://api.dextools.io/v1/pair/0x58f876857a02d6762e0101bb5c46a8c1ed44dc16"

response = requests.get(url)

if response.status_code == 200:
    data = response.json()
    print(f"The current price of {data['token0']['symbol']} is {data['token0Price']} {data['token1']['symbol']}.")
    print(f"The current price of {data['token1']['symbol']} is {data['token1Price']} {data['token0']['symbol']}.")
else:
    print("Error: Could not retrieve data from the API.")
