from typing import Type


class Alg():
    def __init__(self, input):
        self.alg = ''
        if self.valid_input(input):
            self.input = input
        print(self.__repr__())
    
    def __str__(self):
        return self.alg
    
    def __repr__(self):
        return f'<Alg: "{self.alg[:20]}" {self.input[:20]}>'

    def valid_input(self, input):
        if not type(input) is str:
            raise TypeError(f'Invalid input. "{type(input)}" is not str.')
        return True

# debug
if __name__ == "__main__":
    Alg('je;of')