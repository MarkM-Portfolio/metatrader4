__author__ = 'Mark Mon Monteros'

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from webdriver_manager.chrome import ChromeDriverManager
from datetime import datetime
from pytz import timezone
from pathlib import Path
from botocore.exceptions import ClientError
import os, sys, time, boto3

class MT4TechnicalAnalysis():

    def __init__(self):
        self.clock_start = time.time() # Time before the operations start
        self.chart_time = sys.argv[1]
        self.currency = ''
        self.now = datetime.now(timezone('Asia/Manila'))
        self.current_date = self.now.strftime("%m-%d-%Y")
        self.current_time_pst = ''
        self.seconds = ''
        self.minutes = ''
        self.homedir = Path.home()
        self.s3 = boto3.resource("s3")
        self.s3_filedir = ''
        self.s3_bucket = 'tech-analysis'
        self.mql4_home = ''
        self.exec_path = ''
        self.profile = ''

        if (sys.platform == 'linux'):
            self.exec_path = Path('/usr').joinpath('bin').joinpath('google-chrome')
            self.profile = self.homedir.joinpath('.config').joinpath('google-chrome').joinpath('Default')
            self.mql4_home = self.homedir.joinpath('.wine').joinpath('drive_c').joinpath('Program Files (x86)').joinpath('Fullerton Markets Inc MT4').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P')
        if (sys.platform == 'darwin'):
            self.exec_path = Path('/Applications').joinpath('Applications').joinpath('Google Chrome.app').joinpath('Contents').joinpath('MacOs').joinpath('Google Chrome')
            self.profile = self.homedir.joinpath('Library').joinpath('Application Support').joinpath('Google').joinpath('Chrome').joinpath('Profile 1')
            self.mql4_home = self.homedir.joinpath('Library').joinpath('Application Support').joinpath('MetaTrader 4').joinpath('Bottles').joinpath('metatrader64').joinpath('drive_c').joinpath('Program Files (x86)').joinpath('MetaTrader 4').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P') + 'M'
        if (sys.platform == 'windows'):
            self.exec_path = self.homedir.joinpath('AppData').joinpath('Local').joinpath('Google').joinpath('Chrome').joinpath('Application').joinpath('chrome.exe')
            self.profile = self.homedir.joinpath('AppData').joinpath('Local').joinpath('Google').joinpath('Chrome').joinpath('User Data')
            self.mql4_home = self.homedir.joinpath('AppData').joinpath('Roaming').joinpath('MetaQuotes').joinpath('Terminal').joinpath('60464E72AB1410FB355EEFF02B5B34F9').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P')

        self.summary_file = self.homedir.joinpath('Files').joinpath('Summary.txt')
        self.currencies = ['eur-usd', 'gbp-usd', 'aud-usd', 'usd-jpy', 'eur-gbp', 'usd-cad', 'usd-chf', 'nzd-usd']
        # self.currencies = ['eur-usd', 'gbp-usd', 'aud-usd', 'eur-gbp', 'usd-cad', 'usd-chf', 'nzd-usd'] # exclude USDJPY
        # self.currencies = ['eur-usd', 'gbp-usd', 'aud-usd', 'usd-cad', 'usd-chf', 'nzd-usd'] # exclude EURGBP & USDJPY
        self.website = 'https://www.investing.com/technical/'

        options = Options()
        # options.add_argument('--user-data-dir=' + str(self.profile))
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--headless=new")
        options.add_argument("--disable-popup-blocking")

        if (sys.platform == 'linux'):
            self.browser = webdriver.Chrome(options = options, service = Service(ChromeDriverManager().install()))
        else:
            self.browser = webdriver.Chrome(options = options, service = Service(executable_path = self.exec_path))

        self.chart_time_set()
        self.summary_file_create()
        self.launch()

    def chart_time_set(self):
        if (self.chart_time == 'H4' or self.chart_time == 'h4'):
            self.seconds = '18000'
            self.minutes = '240'
        elif (self.chart_time == 'H1' or self.chart_time == 'h1'):
            self.seconds = '3600'
            self.minutes = '60'
        elif (self.chart_time == 'M30' or self.chart_time == 'm30'):
            self.seconds = '1800'
            self.minutes = '30'
        elif (self.chart_time == 'M15' or self.chart_time == 'm15'):
            self.seconds = '900'
            self.minutes = '15'
        elif (self.chart_time == 'M5' or self.chart_time == 'm5'):
            self.seconds = '300'
            self.minutes = '5'
        elif (self.chart_time == 'M1' or self.chart_time == 'm1'):
            self.seconds = '60'
            self.minutes = '1'
        else:
            print('Chart Time Not Available... Exiting!')
            self.exit(1)

    def summary_file_create(self):
        print("\nCreating Summary File " + str(self.summary_file) + '...')
        if (os.path.exists(self.summary_file)):
            os.remove(self.summary_file)

        with open(self.summary_file, 'a') as f:
            f.write(self.current_date + ' ' + self.current_time_pst)
            f.write('\n')

    def launch(self):
        for i in self.currencies:
            self.currency = i.replace('-','').upper()

            if i == 'eur-usd':
                endpoint = 'technical-analysis'
            else:
                endpoint = i + '-technical-analysis'

            self.browser.get(self.website + endpoint)
            xpath = "//*[@id='techSummaryPage']/li[contains(@data-period, " + str(self.seconds) + ")]"
            xpath2 = "//*[@id='techStudiesInnerBoxRight']/div[@class='summary']/span"

            try:
                self.timeframe = WebDriverWait(self.browser,20).until(EC.element_to_be_clickable((By.XPATH, xpath)))
            except TimeoutException as e:
                print("Loading took too much time for ", self.currency, str(e))
                self.write_file(1)
                continue
            else:
                self.timeframe.click()
                self.orderstatus = WebDriverWait(self.browser,20).until(EC.visibility_of_element_located((By.XPATH, xpath2)))
                self.write_file(0)

        self.exit(0)

    def write_file(self, status_code):
        print(self.currency + ':', self.orderstatus.text)

        self.filename = self.currency + str(self.minutes) + '-technical.txt'
        self.output = self.homedir.joinpath('Files').joinpath(self.filename)

        if (status_code != 0):
            with open(self.summary_file, 'a') as f:
                f.write(self.currency + ': NO DATA')
                f.write('\n')

            with open(self.output, 'w') as f:
                f.write('ERROR'.lower())
        else:
            with open(self.summary_file, 'a') as f:
                f.write(self.currency + ': ' + self.orderstatus.text)
                f.write('\n')

            with open(self.summary_file, 'r') as f:
                string = f.read()
                encoded_string = string.encode("utf-8")
                self.s3.Bucket(self.s3_bucket).put_object(Key=self.chart_time + '/Summary.txt', Body=encoded_string)

            with open(self.output, 'w') as f:
                if self.orderstatus.text.startswith('STRONG'):
                    f.write(self.orderstatus.text.replace('STRONG ', '').lower())
                else:
                    f.write('PASS'.lower())

            with open(self.output, 'r') as f:
                string = f.read()
                encoded_string = string.encode("utf-8")
                self.s3.Bucket(self.s3_bucket).put_object(Key=self.chart_time + '/' + self.filename, Body=encoded_string)

    def exit(self, exut_code):
        mm, ss = divmod(time.time() - self.clock_start, 60) # get min and seconds first

        print('\nD O N E !!! \n[ Finished in ', mm, 'Minutes', ss, 'Seconds ]')

        # time.sleep(5) #comment this for timeout testing only
        self.browser.quit()

        if (exut_code != 0):
            sys.exit(1)
        else:
            sys.exit(0)

if __name__ == '__main__':
    print('\nMetaTrader Technical Analysis')
    print('\nCreated by: ' + __author__)

    MT4TechnicalAnalysis()

# ADD ENTRIES TO CRONJOB BEFORE H4 CHART
# 58 * * * *  /usr/bin/python3 /home/ubuntu/metatrader4/technical-analysis.py H4

# ADD ENTRIES TO CRONJOB BEFORE H1 CHART
# 58 * * * *  /usr/bin/python3 /home/ubuntu/metatrader4/technical-analysis.py H1
