from polygon import RESTClient
from typing import cast
from urllib3 import HTTPResponse
import pandas as pd
import json
import lightgbm as lgb
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.stats import norm

api_key = 'your_api_key_from_polygon'

client = RESTClient(api_key)

# Fetch the data
aggs = cast(
    HTTPResponse,
    client.get_aggs(
        'CAT',  
        1,
        'minute',
        '2024-05-01',
        '2024-05-31',
        raw=True
    ),
)

poly_data = json.loads(aggs.data)
poly_data = poly_data['results']

# Check the length of the data to ensure full period coverage
print(f"Number of data points fetched: {len(poly_data)}")

# Prepare the data for DataFrame
dates = []
open_prices = []
high_prices = []
low_prices = []
close_prices = []
volumes = []

for bar in poly_data:
    dates.append(pd.Timestamp(bar['t'], tz='GMT', unit='ms'))
    open_prices.append(bar['o'])
    high_prices.append(bar['h'])
    low_prices.append(bar['l'])
    close_prices.append(bar['c'])
    volumes.append(bar['v'])

data = {
    'Open': open_prices,
    'High': high_prices,
    'Low': low_prices,
    'Close': close_prices,
    'Volume': volumes
}

dataFrame = pd.DataFrame(data, index=dates)

# Getting the mean return
dataFrame['Minute Return'] = dataFrame['Close'].pct_change()
# Drop na values
dataFrame = dataFrame.dropna()

mean_return = dataFrame['Minute Return'].mean()
print(f'Mean Minute Return: {mean_return:.5f}')

plt.figure(figsize=(10,6))

sns.histplot(dataFrame['Minute Return'], bins=500, kde=False, stat='density', color='blue', label='1-Minute Returns')

mean = dataFrame['Minute Return'].mean()
std_dev = dataFrame['Minute Return'].std()
xmin, xmax = plt.xlim()
x = np.linspace(xmin, xmax, 100)
p = norm.pdf(x, mean, std_dev)

plt.title('CAT 1-Minute Returns Distribution (May 2024)')
plt.xlabel('Return')
plt.ylabel('Dencity')
plt.legend()

plt.show()

print(f"Standard Deviation of 1-Minute Returns: {std_dev:.5f}")
