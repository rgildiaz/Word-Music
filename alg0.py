from gutenburg import *
from alg import Alg
import string

mappings = {k: v for k, v in zip(string.printable, range(len(string.printable)))}

# Alg0 writes data to out.txt based on mappings. Supercollider reads out.txt.
class Alg0(Alg):
    def __init__(self, input):
        super().__init__(input)
        print(mappings)
        self.alg = self.output()
    
    def output(self):
        with open('alg_out/out.txt', 'w') as fd:
            data = fd.lines()

    def get_alg(self):
        return self.alg

# debug
if __name__ == "__main__":
    repr(Alg0("jdfkla"))