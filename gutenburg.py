import urllib
import urllib.request as req

class gutenburg():
    def __init__(self, book):
        self.BOOKS = {
            'Frank': 'https://www.gutenberg.org/cache/epub/35062/pg35062.txt'
        }
        self.text = self.load_text(book)
        print('\ntext loaded\n')

    def get_url(self, book):
        try:
            print(self.BOOKS[book])
            return self.BOOKS[book]
        except:
            print('Book URL Missing')
            return None

    def get_remote_text(self, url):
        with req.urlopen(url) as response:
            data = response.read()
            output = data.decode('utf-8')
            return output

    def load_text(self, book):
        url = self.get_url(book)
        return self.get_remote_text(url)

    def get_text(self):
        return self.text

    def write_to_file(self):
        with open('alg_out/gutOut.txt', 'w') as fd:
            for i in self.text:
                try:
                    fd.write(i)
                except:
                    fd.write("EXCEPTION")

if __name__ == '__main__':
    x = gutenburg('Frank')
    print(x.get_text())

    