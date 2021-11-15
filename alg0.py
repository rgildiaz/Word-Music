from gutenburg import *
from alg import Alg
from pythonosc import *
import re
import math

'''
Alg0:
Goal
    Pass values to SuperCollider, allowing some room for randomness. I wanted to avoid a very sound, so I am intentionally avoiding the beeps and bloops that would come from using the first character of each word to determine the pitch, rather aiming for something less defined. This also uses keywords in the text to determine larger scale differences ('rate' or 'tempo' change the tempo, etc.)

Words
    Each token is at least 1 char long. 1st char in each token determines {some important param}. Each other slot has a default value that is changed depending on char in that place.

            Example:
                        W           O            R            D
                        ^           ^            ^            ^
                     quality    velocity=100  reverb=0     pitch=0

    @param quality          Intentionally vague. Letters: generally unpitched. Numbers: generally pitched.
    @param velocity         The velocity of the note. Range=0-35.
    @param reverb           The reverb mix. Range=0-1.
    @param pitch            The degree in SuperCollider's scale/degree system.

    The note is repeated based on the word length. Range=0-inf. Repeats increases with word length (n-letter word = n-3, where n > 2)
    Words are read at 3 words/second.
    Symbols appearing anywhere in a word make that word a Rest() event instead.

Encoding
    Text is sent to SuperCollider through a space-separated .txt file. Tokens can be either control changes or note events Each token is created as follows:

            Example:
                Control:
                     0         0           0
                     ^         ^           ^
                    type  control type   value

                Note:
                     1         0           0           0           0           0
                     ^         ^           ^           ^           ^           ^
                    type    quality     velocity     reverb      pitch      repeats
                    
    Each value is encoded as follows:
        type                0: Control
                            1: Note

        Control
            control type    0: Tempo
                            1: Key
            value           range(0,z) (36 possible values)

        Note
            quality         0: Rest
                            1: Short Perc
                            2: Long Perc
                            3: Short Pitch
                            4: Long Pitch
            velocity        range(0,z) (36 possible values)
            reverb          range(0,z) (36 possible values)
            pitch           range()
'''


keywords = {
    'TEMPO':    ['rate', 'tempo', 'speed'],
    'KEY':      ['key', 'pitch', 'tone']
}

letters = list('abcdefghijklmnopqrstuvwxyz')
numbers = list('0123456789')
mappings = numbers + letters


class Alg0(Alg):
    def __init__(self, input):
        super().__init__(input)
        self.keywords = keywords
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
        with open('alg_out/out.txt', 'w', encoding='utf-8') as fd:
            fd.write(self.output)

    def tokenize_and_clean(self, text):
        replaced = text.replace('\n', ' ')
        lower = replaced.lower()
        out = [i.strip() for i in lower.split(' ')]
        out = [i for i in out if i != '']
        return out

    def process(self):
        tokens = self.tokenize_and_clean(self.input)
        print(tokens[:100])
        for i, token in enumerate(tokens):
            if token in keywords['KEY'] or \
                token in keywords['TEMPO']:
                self.output += ' ' + self.control(token, i)
            else:
                self.output += ' ' + self.note(token)

    '''
    Process a control event and write it to self.output.
    @param ctrl The control word.
    @param modifier The index of the control word
    '''
    def control(self, ctrl, modifier):
        out = '0'

        if ctrl in keywords['TEMPO']:
            out += '0'
        elif ctrl in keywords['KEY']:
            out += '1'

        out += mappings[modifier % len(mappings)]

        return out
    
    '''
    Process a note event and write it to self.output.
    @param note The note word.
    '''
    def note(self, note):
        out = '1'

        # check for Rest
        for i in note:
            if i not in mappings:
                return out + '00000'

        # generally unpitched, coded as 1 or 2
        if note[0] in letters:
            if note[0] in letters[math.floor(len(letters)/2)]:
                out += '1'
            else:
                out += '2'
        # generally pitched, coded as 3 or 4
        elif note[0] in numbers:
            if note[0] in numbers[math.floor(len(numbers)/2)]:
                out += '3'
            else:
                out += '4'
        else:
            raise AssertionError(f'{note[0]} in {note} is not a valid char.')
        
        # if note is at least 2 char long, read its vel
        if len(note) >= 2:
            out += note[1]
        else:
            out += 'h'
        
        # if note is at least 3 char long, read its reverb
        if len(note) >= 3:
            out += note[2]
        else:
            out += 'h'

        # if note is at least 4 char long, read its pitch
        if len(note) >= 4:
            out += note[3]
        else:
            out += 'h'

        # if note is at least 5 char long, count repeats
        if len(note) >= 5:
            # hard cap at len 36
            if len(note) >= 36:
                out += 'z'
            else:
                out += mappings[len(note) - 4]
        else:
            out += '0'

        return out

# debug
if __name__ == "__main__":
    g = gutenburg('Frank')
    x = Alg0(g.get_text())
    print(x)