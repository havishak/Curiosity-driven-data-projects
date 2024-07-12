# Eugene [Butte to Butte](https://buttetobutte.com/) Results Data

## Motivation

Living in Eugene, OR, I'm exposed to the vibrant running and track culture in the town. One annual racing event is the Butte to Butte run, which takes place July 4th eachyear. The two buttes refer to [Spencer Butte](https://en.wikipedia.org/wiki/Spencer_Butte) and [Skinner butte](https://en.wikipedia.org/wiki/Skinner_Butte). My husband and I decided to participate this year. As I was registering, I stumbled upon a trivia challenge: **in which year (and there's only one) did runners from all 50 states participated in the race?**. Since the race results for each year are available online (dating back 2000 though the race started in 1974), I decided to answer this question using my coding and data analytics skills.  

## Approach

In this project, I scraped the results of the Eugene Butte to Butte race, which takes place on every 4th of July in Eugene Oregon, to create a dataset which has participant-level (de-identified) information for all years for which results are public. Then, I used the resulting dataset to find which  year had participants. beyond answering this question, the dataset can be used to answer other race-related questions though I didn't spend much time diving into it.

## Table of Contents

- [Acknowledgments](#acknowledgments)
- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Data Structure](#data-structure)
- [Results](#results)
- [Further Improvement](#further-improvement)
- [License](#license)


## Acknowledgments

I heavily relied on the following resources:

- `rvest` [reference page](https://rvest.tidyverse.org/) by [Hadley Wickham](https://hadley.nz/) 
- SelectorGadget [tool](https://selectorgadget.com/) by [Andrew Cantino](https://github.com/cantino)
- The Rvest & RSelenium [tutorial video](https://www.youtube.com/watch?v=Dkm1d4uMp34) by [Sameer Hijjazi](https://www.youtube.com/@SamerHijjazi)

*Some more thanks:*

- I leaned heavily on StackOverflow and Copilot for troubleshooting, especially when it came to starting a browser with RSelenium and nailing down the webdriver requirements.
- Shoutout to the folks who sparked my interest in web scraping with their applications in classes: [Daniel Anderson](https://github.com/datalorax) and [Owen Jetton](https://cas.uoregon.edu/directory/social-sciences/all/ojetton)
- Finally, thanks and love to my husband, [Piyush Amitabh](https://github.com/pamitabh). He not only mentioned the race to me but also encouraged and brainstormed with me throughout, patiently listening to my endless rants.

## Repository Structure

- **data/**: Contains the scraped dataset in CSV format.
- **scripts/**: Includes RMD walkthrough used for web scraping and data processing as well as analysis


## Installation

To run this project, you will need to have R installed on your machine. I used the following packages: 

- Web-scraping: `rvest` and `RSelenium`
- Scraping supporting: `polite`, `netstat`, `binman`, `wdman`
- Data-wrangling: `tidyverse`, `janitor`

## Data Structure

The resulting data has runner-year-level information for all event formats (10K run, 5K run, 4M walk, 4.5M walk) that took place in given years for thw following years: 2000, 2002-2006, 2009, 2012-2024. No race happened in 2001 and result pages for 2006, 2007, 2010, and 2011 doesn't exist. There are 62,575 rows in total.

The variables are as follows:
- place: int - Place of finish
- sex: chr 
- div: chr - Division in which runner participated (by gender and age-group)
- city: chr - Registered city based on address shared at the time of registering
- state: chr - Registered city based on address shared at the time of registering
- gun_time: chr - Time in min:sec from when the clock started
- net_time: chr - Time in min:sec from when the runner crossed the starting line (only available for later years)
- pace: chr - Runner pace
- sex_place: int - Place of finish in the same sex group
- sex_total: int - Total runners in the same sex group
- div_place: int - Place of finish in the same sex group
- div_total: int - Total runners in the same sex group
- age_graded_score: num - Ratio of a world-class time for a runner's age and gender divided by the runner's actual time (only available for later years)
- start: chr - Time when runner crossed the line in hh:min:sec
- race_format: chr - Race format, one of 10K, 5K, 4M Walk, 4.5M Walk
- race_year: num - Race year

race_year, race_format, place can be used to identify each individual runner.

## Results

![Fig1:](images/b2b_state_codes_year.jpeg)

![Fig2:](images/b2b_state_year.jpeg)

Runners from 51 state codes finished the race in 2016, however, runners from all 50 states in mainland US either didn't finish the race or didn't release their information for public results page. Nevertheless, I answered **2016** and ended up winning a *free registration* for the event.

![Trivia screenshot](images/winning_screenshot.jpg)

We had a fun time at the race - did the 4M walk!!

## Future Improvements

- Upon reviewing the scraped data, I noticed that the state information was only available from 2014 onwards, missing from earlier years. Although I could answer the initial question with the existing data, I plan to find another way to obtain the state information in the future.
- Explore trends and uncover other interesting insights from the data

## License

This repository is licensed under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/). You are free to use, share, and adapt the material as long as you provide appropriate credit to the original author.

## Contact

If you have any questions or suggestions, feel free to reach out to me:

- Email: havishak8@gmail.com
- LinkedIn: [Havisha Khurana](linkedin.com/in/havisha-khurana/)

