## Behance Data Analysis
- Contact: namwkim85@gmail.com
------
#### Requirement
- python, pip, mongodb
- behance API key from https://www.behance.net/dev/
- gender-api.com API key from https://gender-api.com/en/
- After installing the requirements, run the following command on terminal.
```
pip install -r requirements.txt
```
#### Running Crawlers
- When prompted, you need to input an appropriate API key.
1. crawl-recent-projects.py
  - Extract recently uploaded projects from Behance.
2. extract-seed-users.py
  - Extract active users who are the authors of the recent projects.
3. crawl-sample-users.py
  - Use a random walk strategy to sample users from the Behance network based on the seed users.
4. crawl-sample-projects.py
  - Extract projects authored by the sampled users.
5. crawl-sample-collections.py
  - Extract collections authored by the sampled users.
6. crawl-sample-wips.py
  - Extract wips authored by the sampled users.
7. save-users-into-csv.py
  - Convert the sample user data saved in MongoDb into a csv file.

#### Data Analysis Script
- [`analysis`](https://github.com/namwkim/behance-analysis/tree/master/analysis) 

#### Extracting Image Features
- [`img-proc`](https://github.com/namwkim/behance-analysis/tree/master/img-proc) written in Java. The original code is here [link](http://iis.seas.harvard.edu/resources/aesthetics-chi13/)

