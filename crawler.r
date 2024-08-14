import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

class WebCrawler:
    def __init__(self, base_url):
        self.base_url = base_url
        self.visited = set()

    def crawl(self,url):
        if url in self.visited:
            return
        self.visited.add(url)
        print(f"Crawling: {url}")

        try:
            response = requests.get(url)
            if response.status_code != 200:
                print(f"Failed to retrieve {url}")
                return
            
            #Check for sensitive paths
            self.check_sensitive_paths(url)

            #Check for security headers
            self.check_security_headers(response.headers)

            soup = BeautifulSoup(response.text, 'lxml')
            self.find_links(soup, url)

        except requests.RequestException as e:
            print(f"Request failed: {e}")
    
    def find_links(self, soup, current_url):
        for link in soup.find_all('a', href=True):
            href = link ['href']
            absolute_url = urljoin(current_url, href)
            if urlparse(absolute_url).netloc == urlparse(self.base_url).netloc:
                self.crawl(absolute_url)

    def check_sensitive_paths(self, url):
        SENSITIVE_PATHS = ['/admin','/config', '/backup','/hidden','/.git']
        for path in SENSITIVE_PATHS:
            test_url = urljoin(url,path)
            response = requests.get(test_url)
            if response.status_code == 200:
                print(f"Sensitive path found: {test_url}")

    def check_security_headers(self, headers):
        required_headers = [
            'X-Frame-Options',
            'X-XSS-Protection',
            'Strict-Transport-Security',
            'Content-Security-Policy',
            'X-Content-Type-Options'
        ]
        missing_headers = [header for header in required_headers if header not in headers]
        print(f"Missing security headers:{','.join(missing_headers)}")


if __name__ == "__main__":
    base_url = input('Please enter a valid URL starting with http:// or https://:').strip()
    if not (base_url.startswith('http://') or base_url.startswith('https://')):
        print('Error: Please ener a valid URL starting with http(s)://')
    else:
        crawler = WebCrawler(base_url)
        crawler.crawl(base_url)