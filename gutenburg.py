import urllib
import urllib.request as req

class gutenburg():
    def __init__(self, book):
        self.BOOKS = {
            'Frank': 'https://www.gutenberg.org/cache/epub/35062/pg35062.txt'
        }
        self.text = self.load_text(book)
        print('text loaded')

    def get_url(self, book):
        try:
            print(self.BOOKS[book])
            return self.BOOKS[book]
        except:
            print('Book URL Missing')
            return None

    def get_remote_text(self, url):
        # try:
        #     with urllib.request.urlopen(url) as response:
        #         if response.getcode() == 200:
        #             data = response.read()
        #             output = data.decode('utf-8')
        #             return output
        #         else:
        #             print('Response Code: {}'.format(response.getcode()))
        # except urllib.error.HTTPError as e:
        #     print('HTTPError: {}'.format(e.code))
        #     return None
        # except urllib.error.URLError as e:
        #     print('URLError: {}'.format(e.reason))
        #     return None
        with req.urlopen(url) as response:
            data = response.read()
            output = data.decode('utf-8')
            return output

    def load_text(self, book):
        url = self.get_url(book)
        return self.get_remote_text(url)

    def get_text(self):
        return self.text

if __name__ == '__main__':
    x = gutenburg('Frank')
    