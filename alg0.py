from gutenburg import *
from alg import Alg
import string

mappings = {k: v for k, v in zip(string.printable, range(len(string.printable)))}

# Alg0 writes data to out.txt based on mappings. Supercollider reads out.txt.
class Alg0(Alg):
    def __init__(self, input):
        super().__init__(input)
        self.alg = self.output()
        self.mappings = mappings
        print(self.alg)
    
    def output(self):
        with open('alg_out/out.txt', 'w', encoding='utf-8') as fd:
            for i in self.input:
                try:
                    fd.write(str(mappings[i]) + ' ')
                except:
                    # for now, ignore exception cases like ë or æ (fix later?) 
                    fd.write('')
        return str(mappings)

    def get_alg(self):
        return self.alg

    def process(self):
        pass

# debug
if __name__ == "__main__":
    g = gutenburg('Frank')
    x = Alg0(g.get_text())
    g.write_to_file()
    print(x)