from gutenburg import *
from alg import Alg
from pythonosc import *
import math
import string

'''
Alg1:
Goal
    Pass values to SuperCollider through out1.txt. Slippery sliding.

Words
    Each token is at least 1 char long. Words are encoded as follows:

            Example:
                        W           O           R         D     S
                        ^           ^           ^         ^     ^
                     amplitude  amp_curve   pitch_curve   AM    FM

        @param amplitude        The note's amplitude.
        @param amp_curve        The note's amplitude curve. Uses SC's curve system. Time before and after the peak is calculated with   space between vowels.
        @param pitch_curve      The note's curve from starting pitch to ending pitch.
        @param AM               AM amount, using the note 2 notes ago
        @param FM               FM amount, using the previous note

    Pitch is calculated using the starting and ending char.
    Note duration is based on word length. Each letter is 1/3 of a beat

Encoding
    Text is sent to SuperCollider through a space-separated .txt file. Tokens at this point are all note events. Each token is created as follows:

            Example:
                Note:
                     1         00          00         00        00     00
                     ^         ^           ^          ^         ^      ^
                    note    amplitude   amp_curve  pitch_curve  AM     FM
'''

class Alg1(Alg):
    def __init__(self, input):
        super().__init__(input)
        self.output = ''
        self.pipeline()
    
    def pipeline(self):
        self.is_string()
        self.process()
        self.write()
        print(self.output[:100])
        
    def is_string(self):
        if type(self.input) is not str:
            raise TypeError(f'Input must be a string. {type(self.input)} given.')
        return True

    '''
    Write to alg_out/out.txt.
    '''
    def write(self):
        with open('alg_out/out1.txt', 'w', encoding='utf-8') as fd:
            fd.write(self.output)

    def tokenize_and_clean(self, text):
        replaced = text.replace('\n', ' ')
        lower = replaced.lower()
        out = [i.strip() for i in lower.split(' ')]
        out = [i for i in out if i != '']
        for i, x in enumerate(out):
            for j, y in enumerate(x):
                if y not in string.ascii_letters:
                    out[i] = out[i].replace(y, "0")
        return out

    def process(self):
        tokens = self.tokenize_and_clean(self.input)
        print(tokens[:100])
        for i, token in enumerate(tokens):
            self.output += ' ' + self.note(token)
        self.output = self.output.strip()
    
    '''
    Process a note event and write it to self.output.
    @param note The note word.
    '''
    def note(self, note):
        out = '1'

        # check for Rest
        for i in note:
            if i not in string.ascii_letters:
                return out + '0'*7
            if i not in string.printable:
                raise AssertionError(f'{note[0]} in {note} is not a valid char.')
        
        # if note is at least 2 char long, read its vel
        if len(note) >= 2:
            out += f"{string.printable.index(note[1])%100:02}"
        else:
            out += '50'
        
        # if note is at least 3 char long, read its pitch
        if len(note) >= 3:
            out += f"{string.printable.index(note[2])%100:02}"
        else:
            out += '50'

        # if note is at least 4 char long, count repeats
        if len(note) >= 5:
            # note of len 4 will play twice. Wraps at 100
            out += f"{(len(note)-2)%100:02}"
        else:
            out += '01'

        return out

# debug
if __name__ == "__main__":
    lorem = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas efficitur mi sit amet odio elementum, ac vestibulum diam euismod. Aenean ultricies mollis turpis, non bibendum mi suscipit id. Vestibulum vulputate lacus lacus, et pulvinar dui suscipit nec. Nulla rutrum urna quis odio imperdiet egestas. Curabitur sit amet feugiat massa. Suspendisse potenti. Donec rhoncus sapien ac consequat suscipit. Cras fermentum congue interdum. Duis eget lacinia velit. Vivamus blandit posuere massa nec porta. Ut lacus nibh, tincidunt at erat vel, interdum faucibus erat. Praesent sodales maximus mi, ut bibendum ipsum varius dapibus. Pellentesque sed nisi vitae ligula condimentum fermentum sed ac mauris. Phasellus tempor aliquet urna, id volutpat tellus blandit a. Fusce vel tincidunt risus. Aliquam tincidunt, nibh vel dignissim accumsan, erat nisl ornare massa, id blandit lacus turpis et diam.\nProin ut iaculis turpis. Mauris in nisl ullamcorper, hendrerit turpis et, mattis leo. Sed vel elit in urna dignissim dapibus eget nec odio. Integer ultricies id risus quis blandit. Duis non libero nisl. Ut sit amet dolor sem. Sed venenatis molestie vehicula. Donec interdum arcu ac quam porttitor, sollicitudin suscipit risus auctor. Curabitur diam mauris, suscipit et libero sed, facilisis aliquam quam. Donec interdum hendrerit felis, efficitur vestibulum magna eleifend eget. Nunc nibh leo, viverra ut dui id, dictum ultrices sapien. Integer pulvinar orci sit amet purus fermentum, non mattis augue volutpat. Etiam tellus nunc, aliquam vitae ipsum in, sagittis luctus tellus. Mauris luctus dui nec suscipit gravida. Ut ac turpis ac nibh molestie accumsan. \nInteger euismod bibendum dolor, eget commodo neque ultricies molestie. Quisque dui odio, consectetur at euismod nec, sodales sit amet arcu. Quisque eleifend justo vel odio finibus consectetur. Aenean auctor nisl at dignissim pellentesque. Suspendisse porta dolor condimentum, eleifend ipsum eget, venenatis mi. Sed rutrum leo eu porta finibus. Aliquam quis nibh placerat, lacinia ante non, tempus purus. Aliquam nulla ligula, pellentesque in purus gravida, ultrices pellentesque est. Phasellus volutpat dui a lectus ultrices, nec vulputate sem accumsan. Cras eu urna eu nisl mattis semper. Sed vehicula rutrum erat eget auctor. Vivamus turpis tellus, rhoncus sed varius nec, accumsan quis nunc. Duis sagittis at justo ac sollicitudin. Fusce pharetra nisi nec ante vehicula ullamcorper. Integer porta nec libero in luctus. \nPellentesque consequat urna nec accumsan suscipit. Phasellus in pulvinar elit. Sed posuere odio non mi iaculis tristique. Cras pharetra libero quis ante interdum pretium sed eu ex. Morbi rhoncus nulla sed mollis pretium. Integer a pulvinar enim, sollicitudin facilisis est. In iaculis turpis augue, non semper massa vulputate sit amet. \nNullam et purus lectus. Ut vel nulla sapien. Aenean vulputate metus a nisl pretium mattis vel sed magna. Suspendisse eleifend, neque in lacinia egestas, ex odio suscipit lectus, id facilisis dui augue vitae ex. Etiam mattis sit amet metus et aliquet. Phasellus venenatis ligula sit amet urna consectetur, eu aliquam dolor venenatis. Aliquam faucibus sit amet tellus non suscipit. Ut porta massa at erat fermentum congue. Quisque vehicula massa sem, ac ornare libero consectetur non. Aenean lobortis rhoncus arcu, ut pulvinar arcu ullamcorper at. Nunc id nisl a libero hendrerit lacinia quis sed ipsum. Cras cursus elit at dapibus cursus. Suspendisse consectetur risus ut tempus pellentesque. Vivamus sit amet finibus mi, ut mollis libero.'
    # x = Alg1(lorem)
    # print(x)
    print(len(string.printable), string.printable)

    this =  ['apple', 'ban34na', 'pear']
    for i, x in enumerate(this):
        for j, y in enumerate(x):
            if y not in string.ascii_letters:
                this[i] = this[i].replace(y, "a")

    print(this)