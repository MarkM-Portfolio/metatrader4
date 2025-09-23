__author__ = 'Mark Mon Monteros'

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.common.exceptions import ElementClickInterceptedException
from webdriver_manager.chrome import ChromeDriverManager
from datetime import datetime
from pytz import timezone
from pathlib import Path
from botocore.exceptions import ClientError
import os, sys, subprocess, boto3

class MT4NewsScheduler():

    def __init__(self):
        self.now = datetime.now(timezone('Asia/Manila'))
        self.current_date = self.now.strftime("%m-%d-%Y")
        self.current_time_pst = self.now.strftime("%H-%M%Z")
        self.homedir = Path.home()
        self.s3 = boto3.resource("s3")
        self.s3_client = boto3.client('s3')
        self.s3_filedir = ''
        self.s3_bucket = 'tech-analysis'
        self.mql4_home = ''
        self.exec_path = ''
        self.profile = ''
        self.calendar = ''
        self.currency = []
        self.news_time = []
        
        if (sys.platform == 'linux'):
            self.exec_path = Path('/usr').joinpath('bin').joinpath('google-chrome')
            self.profile = self.homedir.joinpath('.config').joinpath('google-chrome').joinpath('Default')
            self.mql4_home = self.homedir.joinpath('.mt4').joinpath('drive_c').joinpath('Program Files (x86)').joinpath('MetaTrader 4').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P')
        if (sys.platform == 'darwin'):
            self.exec_path = Path('/Applications').joinpath('Applications').joinpath('Google Chrome.app').joinpath('Contents').joinpath('MacOs').joinpath('Google Chrome')
            self.profile = self.homedir.joinpath('Library').joinpath('Application Support').joinpath('Google').joinpath('Chrome').joinpath('Profile 1')
            # self.mql4_home = self.homedir.joinpath('Library').joinpath('Application Support').joinpath('MetaTrader 4').joinpath('Bottles').joinpath('metatrader64').joinpath('drive_c').joinpath('Program Files (x86)').joinpath('MetaTrader 4').joinpath('MQL4')
            self.mql4_home = self.homedir.joinpath('Library').joinpath('Application Support').joinpath('net.metaquotes.wine.metatrader4').joinpath('drive_c').joinpath('Program Files (x86)').joinpath('MetaTrader 4').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P') + 'M'
        if (sys.platform == 'windows'):
            self.exec_path = self.homedir.joinpath('AppData').joinpath('Local').joinpath('Google').joinpath('Chrome').joinpath('Application').joinpath('chrome.exe')
            self.profile = self.homedir.joinpath('AppData').joinpath('Local').joinpath('Google').joinpath('Chrome').joinpath('User Data')
            self.mql4_home = self.homedir.joinpath('AppData').joinpath('Roaming').joinpath('MetaQuotes').joinpath('Terminal').joinpath('60464E72AB1410FB355EEFF02B5B34F9').joinpath('MQL4')
            self.current_time_pst = self.now.strftime('%I:%M %P')

        self.summary_file = self.mql4_home.joinpath('Files').joinpath('News-Summary.txt')
        self.data_curr_file = self.mql4_home.joinpath('Files').joinpath('News-DataCurr.txt')
        self.data_time_file = self.mql4_home.joinpath('Files').joinpath('News-DataTime.txt')

        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--headless=new")
        options.add_argument("--disable-popup-blocking")

        if (sys.platform == 'linux' or sys.platform == 'darwin'):
            # self.browser = webdriver.Chrome(options = options, service = Service(ChromeDriverManager().install()))
            self.browser = webdriver.Chrome(options = options, service = Service())
        else:
            self.browser = webdriver.Chrome(options = options, service = Service(executable_path = self.exec_path))

        self.website = 'https://www.investing.com/economic-calendar'

        self.summary_file_create()
        self.launch()

    def summary_file_create(self):
        print("\nCreating Summary File " + str(self.summary_file) + '...')

        for file in os.listdir(self.mql4_home.joinpath('Files')):
            if file.endswith('-news.txt'):
                try:
                    os.remove(self.mql4_home.joinpath('Files').joinpath(file))
                except Exception as e:
                    print(str(e))

        if (os.path.exists(self.data_curr_file)):
            os.remove(self.data_curr_file)

        if (os.path.exists(self.data_time_file)):
            os.remove(self.data_time_file)

        if (os.path.exists(self.summary_file)):
            os.remove(self.summary_file)

        with open(self.summary_file, 'a') as f:
            f.write(self.current_date + ' ' + self.current_time_pst)
            f.write('\n')

    def launch(self):
        self.browser.get(self.website)
        self.browser.maximize_window()
        print(self.browser.text)
        # self.news_today()

    def news_today(self):
        print("\nGetting data from " + self.website + '...')

        # TEST ONLY
        # yesterday = 'timeFrame_yesterday'
        # tomorrow = 'timeFrame_tomorrow'
        # try:
        #     self.test_date = WebDriverWait(self.browser,60).until(EC.element_to_be_clickable((By.ID, yesterday)))
        #     # self.test_date = WebDriverWait(self.browser,60).until(EC.element_to_be_clickable((By.ID, tomorrow)))
        # except TimeoutException as e:
        #     print("Loading took too much time for timezone selection.", str(e))
        #     self.exit(1)
        # else:
        #     self.browser.execute_script("arguments[0].click();", self.test_date)
        #     # self.test_date.click()

        # FILTER IMPACTED ONLY
        try:
            self.filter = WebDriverWait(self.browser,20).until(EC.element_to_be_clickable((By.ID, "filterStateAnchor")))
        except TimeoutException as e:
            print("Loading took too much time for timezone selection.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.filter)
            # self.filter.click()

        try:
            self.impact_high = WebDriverWait(self.browser,20).until(EC.element_to_be_clickable((By.ID, "importance3")))
        except TimeoutException as e:
            print("Loading took too much time for timezone selection.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.impact_high)
            # self.impact_high.click()

        try:
            self.display_time = WebDriverWait(self.browser,20).until(EC.element_to_be_clickable((By.ID, "timetimeOnly")))
        except TimeoutException as e:
            print("Loading took too much time for timezone selection.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.display_time)
            # self.impact_high.click()

        try:
            self.apply = WebDriverWait(self.browser,20).until(EC.element_to_be_clickable((By.ID, "ecSubmitButton")))
        except TimeoutException as e:
            print("Loading took too much time for timezone selection.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.apply)
            # self.apply.click()

        # CHANGE TIMEZONE TO LOCAL TIME
        try:
            self.timezone = WebDriverWait(self.browser,40).until(EC.element_to_be_clickable((By.XPATH, "//span[@class='dropDownArrowGray']")))
        except TimeoutException as e:
            print("Loading took too much time for timezone selection.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.timezone)
            # self.timezone.click()
        
        try:
            self.change_time = WebDriverWait(self.browser,40).until(EC.element_to_be_clickable((By.ID, "liTz178")))
        except TimeoutException as e:
            print("Loading took too much time for change time.", str(e))
            self.exit(1)
        else:
            self.browser.execute_script("arguments[0].click();", self.change_time)
            # self.change_time.click()

        try:
            self.calendar = WebDriverWait(self.browser,60).until(EC.visibility_of_element_located((By.ID, "economicCalendarData")))
        except TimeoutException as e:
            print("Loading took too much time for change time.", str(e))
            self.exit(1)
        else:
            self.write_file()

    def write_file(self):
        with open(self.summary_file, 'a') as f:
            f.write(self.calendar.text)
            f.write('\n')

        # Save to S3 Bucket
        # with open(self.summary_file, 'r') as f:
        #     string = f.read()
        #     encoded_string = string.encode("utf-8")

            # objects = self.s3_client.list_objects(Bucket=self.s3_bucket, Prefix='NEWS/')

            # try:
            #     for obj in objects['Contents']:
            #         self.s3_client.delete_object(Bucket=self.s3_bucket, Key=obj['Key'])
            # except KeyError as e:
            #     print("No Files in S3 Bucket.. Creating NEWS Folder..", str(e))
            #     self.s3_client.put_object(Bucket=self.s3_bucket, Key=('NEWS/'))

            # self.s3.Bucket(self.s3_bucket).put_object(Key='NEWS/News-Summary.txt', Body=encoded_string)

        cmd = ['cat', self.summary_file]
        cmd1 = ['uniq']
        cmd2 = ['tail', '-n', '+4']
        cmd3 = ['grep', '-v', 'Holiday\\|^All'] # exclude holday
        cmd4 = ['awk', '{print$2 " " $1}']
        cmd5 = ['uniq'] # remove duplicate hours:mins
        cmd6 = ['sed', '-e', 's/[[:blank:]]0/ /g'] # normalize hours
        cmd7 = ['uniq'] # remove duplicate time
        # currency strip
        cmd8 = ['awk', '{print$1}'] # get currencies only
        # time strip
        cmd9 = ['awk', '{print$2}'] # get time only

        ps = subprocess.run(cmd, check=True, capture_output=True)
        ps1 = subprocess.run(cmd1, input=ps.stdout, capture_output=True)
        ps2 = subprocess.run(cmd2, input=ps1.stdout, capture_output=True)
        ps3 = subprocess.run(cmd3, input=ps2.stdout, capture_output=True)
        ps4 = subprocess.run(cmd4, input=ps3.stdout, capture_output=True)
        ps5 = subprocess.run(cmd5, input=ps4.stdout, capture_output=True)
        ps6 = subprocess.run(cmd6, input=ps5.stdout, capture_output=True)
        ps7 = subprocess.run(cmd7, input=ps6.stdout, capture_output=True)
        # output = ps7.stdout.decode('utf-8').strip()
        # currency strip
        ps8 = subprocess.run(cmd8, input=ps7.stdout, capture_output=True)
        currencies = ps8.stdout.decode('utf-8').strip()
        # time strip
        ps9 = subprocess.run(cmd9, input=ps7.stdout, capture_output=True)
        hours = ps9.stdout.decode('utf-8').strip()

        with open(self.data_curr_file, 'w') as f:
            f.write(currencies)

        with open(self.data_curr_file, 'r') as f:
           for line in f:
                self.currency.append(line.strip())

        with open(self.data_time_file, 'w') as f:
            f.write(hours)

        with open(self.data_time_file, 'r') as f:
           for line in f:
                self.news_time.append(line.strip())

        count = 0
        for idx, i in enumerate(self.currency):
            count += 1
            self.filename = i + str(count) + '-news.txt'
            self.output = self.mql4_home.joinpath('Files').joinpath(self.filename)
            for idx2, j in enumerate(self.news_time):
                if idx == idx2:
                    with open(self.output, 'w') as f:
                        f.write(j)
                    # Save to S3 Bucket
                    # with open(self.output, 'r') as f:
                    #     string = f.read()
                    #     encoded_string = string.encode("utf-8")
                        # self.s3.Bucket(self.s3_bucket).put_object(Key='NEWS/' + self.filename, Body=encoded_string)
                    continue

        self.exit(0)

    def exit(self, exut_code):
        # time.sleep(5) #comment this for timeout testing only
        self.browser.quit()

        if (exut_code != 0):
            sys.exit(1)
        else:
            sys.exit(0)


if __name__ == '__main__':
    print('\nMetaTrader News Scheduler')
    print('\nCreated by: ' + __author__)

    MT4NewsScheduler()

    print('\n\nDONE...!!!\n')


    # ADD ENTRIES TO CRONJOB
    # */15 00 * * * /usr/bin/python3 news-scheduler-AWS.py
