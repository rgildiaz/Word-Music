import urllib
import urllib.request as req

class gutenburg():
    '''
    gutenburg

    Get a book from project gutenberg.
    '''
    def __init__(self, book):
        self.BOOKS = {
            'Bird': 'https://www.gutenberg.org/cache/epub/35062/pg35062.txt'
        }
        self.text = ""
        self.book = book
        self.lorem = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas efficitur mi sit amet odio elementum, ac vestibulum diam euismod. Aenean ultricies mollis turpis, non bibendum mi suscipit id. Vestibulum vulputate lacus lacus, et pulvinar dui suscipit nec. Nulla rutrum urna quis odio imperdiet egestas. Curabitur sit amet feugiat massa. Suspendisse potenti. Donec rhoncus sapien ac consequat suscipit. Cras fermentum congue interdum. Duis eget lacinia velit. Vivamus blandit posuere massa nec porta. Ut lacus nibh, tincidunt at erat vel, interdum faucibus erat. Praesent sodales maximus mi, ut bibendum ipsum varius dapibus. Pellentesque sed nisi vitae ligula condimentum fermentum sed ac mauris. Phasellus tempor aliquet urna, id volutpat tellus blandit a. Fusce vel tincidunt risus. Aliquam tincidunt, nibh vel dignissim accumsan, erat nisl ornare massa, id blandit lacus turpis et diam.\nProin ut iaculis turpis. Mauris in nisl ullamcorper, hendrerit turpis et, mattis leo. Sed vel elit in urna dignissim dapibus eget nec odio. Integer ultricies id risus quis blandit. Duis non libero nisl. Ut sit amet dolor sem. Sed venenatis molestie vehicula. Donec interdum arcu ac quam porttitor, sollicitudin suscipit risus auctor. Curabitur diam mauris, suscipit et libero sed, facilisis aliquam quam. Donec interdum hendrerit felis, efficitur vestibulum magna eleifend eget. Nunc nibh leo, viverra ut dui id, dictum ultrices sapien. Integer pulvinar orci sit amet purus fermentum, non mattis augue volutpat. Etiam tellus nunc, aliquam vitae ipsum in, sagittis luctus tellus. Mauris luctus dui nec suscipit gravida. Ut ac turpis ac nibh molestie accumsan. \nInteger euismod bibendum dolor, eget commodo neque ultricies molestie. Quisque dui odio, consectetur at euismod nec, sodales sit amet arcu. Quisque eleifend justo vel odio finibus consectetur. Aenean auctor nisl at dignissim pellentesque. Suspendisse porta dolor condimentum, eleifend ipsum eget, venenatis mi. Sed rutrum leo eu porta finibus. Aliquam quis nibh placerat, lacinia ante non, tempus purus. Aliquam nulla ligula, pellentesque in purus gravida, ultrices pellentesque est. Phasellus volutpat dui a lectus ultrices, nec vulputate sem accumsan. Cras eu urna eu nisl mattis semper. Sed vehicula rutrum erat eget auctor. Vivamus turpis tellus, rhoncus sed varius nec, accumsan quis nunc. Duis sagittis at justo ac sollicitudin. Fusce pharetra nisi nec ante vehicula ullamcorper. Integer porta nec libero in luctus. \nPellentesque consequat urna nec accumsan suscipit. Phasellus in pulvinar elit. Sed posuere odio non mi iaculis tristique. Cras pharetra libero quis ante interdum pretium sed eu ex. Morbi rhoncus nulla sed mollis pretium. Integer a pulvinar enim, sollicitudin facilisis est. In iaculis turpis augue, non semper massa vulputate sit amet. \nNullam et purus lectus. Ut vel nulla sapien. Aenean vulputate metus a nisl pretium mattis vel sed magna. Suspendisse eleifend, neque in lacinia egestas, ex odio suscipit lectus, id facilisis dui augue vitae ex. Etiam mattis sit amet metus et aliquet. Phasellus venenatis ligula sit amet urna consectetur, eu aliquam dolor venenatis. Aliquam faucibus sit amet tellus non suscipit. Ut porta massa at erat fermentum congue. Quisque vehicula massa sem, ac ornare libero consectetur non. Aenean lobortis rhoncus arcu, ut pulvinar arcu ullamcorper at. Nunc id nisl a libero hendrerit lacinia quis sed ipsum. Cras cursus elit at dapibus cursus. Suspendisse consectetur risus ut tempus pellentesque. Vivamus sit amet finibus mi, ut mollis libero.'
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

    def load_text(self):
        url = self.get_url(self.book)
        return self.get_remote_text(url)

    def set_text(self, text):
        self.text = text

    def get_text(self):
        return self.text

    def write_to_file(self):
        with open('alg_out/gutOut.txt', 'w') as fd:
            for i in self.text:
                try:
                    fd.write(i)
                except:
                    fd.write("EXCEPTION")

    def get_lorem(self):
        return self.lorem

if __name__ == '__main__':
    x = gutenburg()
    print(x.get_lorem())