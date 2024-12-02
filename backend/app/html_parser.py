from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def scrape_website(url):
    """
    Generalized Selenium script to scrape any website.

    Args:
        url (str): The URL of the webpage.

    Returns:
        dict: A dictionary containing extracted website data.
    """
    # Set up Selenium with Chrome WebDriver
    chrome_options = Options()
    chrome_options.add_argument("--headless")  # Run in headless mode
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")

    # Replace 'path/to/chromedriver' with the actual path to your ChromeDriver executable
    service = Service("path/to/chromedriver")
    driver = webdriver.Chrome(service=service, options=chrome_options)

    try:
        # Navigate to the website
        driver.get(url)

        # Wait for the page to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "body"))
        )

        # Extract all visible text
        visible_text = driver.find_element(By.TAG_NAME, "body").text

        # Extract links
        links = [
            a.get_attribute("href")
            for a in driver.find_elements(By.TAG_NAME, "a")
            if a.get_attribute("href")
        ]

        # Extract headings
        headings = {}
        for level in range(1, 7):  # h1 to h6
            headings[f"h{level}"] = [
                h.text for h in driver.find_elements(By.TAG_NAME, f"h{level}")
            ]

        # Extract tables
        tables = []
        table_elements = driver.find_elements(By.TAG_NAME, "table")
        for table in table_elements:
            rows = table.find_elements(By.TAG_NAME, "tr")
            table_data = []
            for row in rows:
                cells = row.find_elements(By.TAG_NAME, "td") + row.find_elements(
                    By.TAG_NAME, "th"
                )
                table_data.append([cell.text for cell in cells])
            tables.append(table_data)

        # Extract lists
        lists = []
        ul_elements = driver.find_elements(By.TAG_NAME, "ul") + driver.find_elements(
            By.TAG_NAME, "ol"
        )
        for ul in ul_elements:
            list_items = ul.find_elements(By.TAG_NAME, "li")
            lists.append([item.text for item in list_items])

        # Return extracted data
        return {
            "visible_text": visible_text,
            "links": links,
            "headings": headings,
            "tables": tables,
            "lists": lists,
        }

    except Exception as e:
        print(f"Error scraping the website: {e}")
        return None

    finally:
        # Close the browser
        driver.quit()


# Example usage
url = "https://toyotaconnected.com/job?gh_jid=7531523002&did=4040990002"
scraped_data = scrape_website(url)

if scraped_data:
    print(
        "\nVisible Text:\n", scraped_data["visible_text"][:500]
    )  # Preview first 500 characters
    print("\nLinks:\n", scraped_data["links"][:10])  # Preview first 10 links
    print("\nHeadings:\n", scraped_data["headings"])
    print("\nTables:\n", scraped_data["tables"])
    print("\nLists:\n", scraped_data["lists"])
