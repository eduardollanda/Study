import os

## codigo muito besta apenas para dois amigos preguiçosos
def main():
    

    add = "git add ."
    commit = "git commit -m \"Upando qualquer coisa so por que eu sou preguiçoso\""
    push = "git push origin master"

    os.system(add)
    os.system(commit)
    os.system(push)
    

main()