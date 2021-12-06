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
                     1      00    00    00      00          00         00           00     00
                     ^      ^     ^     ^       ^           ^          ^            ^      ^
                    note   dur   freq1  freq 2  amplitude   amp_curve  pitch_curve  AM     FM
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
    # x = Alg1(lorem)
    # print(x)
    print(len(string.printable), string.printable)